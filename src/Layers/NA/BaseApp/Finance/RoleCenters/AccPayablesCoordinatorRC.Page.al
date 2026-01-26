// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.BankAccount;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Task;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Threading;

page 9002 "Acc. Payables Coordinator RC"
{
    Caption = 'Accounts Payable Coordinator';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            group(Control1900724808)
            {
                ShowCaption = false;
                part(Control1900601808; "Acc. Payables Activities")
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Control1900724708)
            {
                ShowCaption = false;
                part(Control1902476008; "My Vendors")
                {
                    ApplicationArea = Basic, Suite;
                }
                part(Control10; "Report Inbox Part")
                {
                    ApplicationArea = Basic, Suite;
                }
                part(Control12; "My Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                systempart(Control1901377608; MyNotes)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
#if not CLEAN28
            action("&Vendor - List")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Vendor - List (Obsolete)';
                Image = "Report";
                RunObject = Report "Vendor - List";
                ToolTip = 'View the list of your vendors.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release. See the documentation for alternative options.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Vendor - Listing")
            {
                Caption = 'Vendor - Listing';
                Image = "Report";
                RunObject = Report "Vendor - Listing";
                ToolTip = 'View quick-reference information about vendor accounts and balances.';
            }
            action("Vendor - &Balance to date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - &Balance to date';
                Image = "Report";
                RunObject = Report "Vendor - Balance to Date";
                ToolTip = 'View, print, or save a detail balance to date for selected vendors.';
            }
            action("Aged Accounts Payable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Aged Accounts Payable';
                Image = "Report";
                RunObject = Report "Aged Accounts Payable NA";
                ToolTip = 'View an overview of when your payables to vendors are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
            }
            action("Vendor Account Detail")
            {
                Caption = 'Vendor Account Detail';
                Image = "Report";
                RunObject = Report "Vendor Account Detail";
                ToolTip = 'View the detailed account activity for each vendor for a specific period of time. The report lists all activity with running account balances, or only open items or only closed items with totals of either. The report can also show the application of payments to invoices.';
            }
            action("Open Vendor Entries")
            {
                Caption = 'Open Vendor Entries';
                Image = "Report";
                RunObject = Report "Open Vendor Entries";
                ToolTip = 'View open vendor entries. This report lists the open entries for each vendor, and shows the age (days overdue) and remaining amount due in the transaction currency for each open entry.';
            }
            action("Vendor - &Purchase List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - &Purchase List';
                Image = "Report";
                RunObject = Report "Vendor - Purchase List";
                ToolTip = 'View a list of your purchases in a period, for example, to report purchase activity to customs and tax authorities.';
            }
#if not CLEAN28
            action("Pa&yments on Hold")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Pa&yments on Hold (Obsolete)';
                Image = "Report";
                RunObject = Report "Payments on Hold";
                ToolTip = 'View a list of all vendor ledger entries on which the On Hold field is marked.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release. See the documentation for alternative options.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Vendor Purchase Statistics")
            {
                ApplicationArea = Suite;
                Caption = 'Vendor Purchase Statistics';
                Image = "Report";
                RunObject = Report "Vendor Purchase Statistics";
                ToolTip = 'View a list of amounts for purchases, invoice discount and payment discount in $ for each vendor.';
            }
            action("Cash Requirem. by Due Date")
            {
                Caption = 'Cash Requirem. by Due Date';
                Image = "Report";
                RunObject = Report "Cash Requirements by Due Date";
                ToolTip = 'View cash requirements for a specific due date. The report includes open entries that are not on hold. Based on these entries, the report calculates the values for the remaining amount and remaining amount in the local currency.';
            }
            separator(Action63)
            {
            }
            separator(Action29)
            {
            }
        }
        area(embedding)
        {
            ToolTip = 'View and process vendor payments, and approve incoming documents.';
            action(Vendors)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendors';
                Image = Vendor;
                RunObject = Page "Vendor List";
                ToolTip = 'View or edit detailed information for the vendors that you trade with. From each vendor card, you can open related information, such as purchase statistics and ongoing orders, and you can define special prices and line discounts that the vendor grants you if certain conditions are met.';
            }
            action(VendorsBalance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance';
                Image = Balance;
                RunObject = Page "Vendor List";
                RunPageView = where("Balance (LCY)" = filter(<> 0));
                ToolTip = 'View a summary of the bank account balance in different periods.';
            }
            action("Purchase Orders")
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Orders';
                RunObject = Page "Purchase Order List";
                ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
            }
            action("Purchase Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Invoices';
                RunObject = Page "Purchase Invoices";
                ToolTip = 'Create purchase invoices to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase invoices dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase invoices can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
            }
            action("Purchase Return Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Return Orders';
                RunObject = Page "Purchase Return Order List";
                ToolTip = 'Create purchase return orders to mirror sales return documents that vendors send to you for incorrect or damaged items that you have paid for and then returned to the vendor. Purchase return orders enable you to ship back items from multiple purchase documents with one purchase return and support warehouse documents for the item handling. Purchase return orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature. Note: If you have not yet paid for an erroneous purchase, you can simply cancel the posted purchase invoice to automatically revert the financial transaction.';
            }
            action("Purchase Credit Memos")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Credit Memos';
                RunObject = Page "Purchase Credit Memos";
                ToolTip = 'Create purchase credit memos to mirror sales credit memos that vendors send to you for incorrect or damaged items that you have paid for and then returned to the vendor. If you need more control of the purchase return process, such as warehouse documents for the physical handling, use purchase return orders, in which purchase credit memos are integrated. Purchase credit memos can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature. Note: If you have not yet paid for an erroneous purchase, you can simply cancel the posted purchase invoice to automatically revert the financial transaction.';
            }
            action("Bank Accounts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Accounts';
                Image = BankAccount;
                RunObject = Page "Bank Account List";
                ToolTip = 'View or set up detailed information about your bank account, such as which currency to use, the format of bank files that you import and export as electronic payments, and the numbering of checks.';
            }
            action(Items)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action(PurchaseJournals)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Journals';
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(Purchases),
                                    Recurring = const(false));
                ToolTip = 'Post any purchase-related transaction directly to a vendor, bank, or general ledger account instead of using dedicated documents. You can post all types of financial purchase transactions, including payments, refunds, and finance charge amounts. Note that you cannot post item quantities with a purchase journal.';
            }
            action(PaymentJournals)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Journals';
                Image = Journals;
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(Payments),
                                    Recurring = const(false));
                ToolTip = 'Register payments to vendors. A payment journal is a type of general journal that is used to post outgoing payment transactions to G/L, bank, customer, vendor, employee, and fixed assets accounts. The Suggest Vendor Payments functions automatically fills the journal with payments that are due. When payments are posted, you can export the payments to a bank file for upload to your bank if your system is set up for electronic banking. You can also issue computer checks from the payment journal.';
            }
            action(GeneralJournals)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'General Journals';
                Image = Journal;
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(General),
                                    Recurring = const(false));
                ToolTip = 'Post financial transactions directly to general ledger accounts and other accounts, such as bank, customer, vendor, and employee accounts. Posting with a general journal always creates entries on general ledger accounts. This is true even when, for example, you post a journal line to a customer account, because an entry is posted to a general ledger receivables account through a posting group.';
            }
        }
        area(sections)
        {
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                ToolTip = 'View posted purchase invoices and credit memos, and analyze G/L registers.';
                action("Posted Purchase Receipts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Purchase Receipts';
                    RunObject = Page "Posted Purchase Receipts";
                    ToolTip = 'Open the list of posted purchase receipts.';
                }
                action("Posted Purchase Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Purchase Invoices';
                    RunObject = Page "Posted Purchase Invoices";
                    ToolTip = 'Open the list of posted purchase invoices.';
                }
                action("Posted Purchase Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Purchase Credit Memos';
                    RunObject = Page "Posted Purchase Credit Memos";
                    ToolTip = 'Open the list of posted purchase credit memos.';
                }
                action("Posted Return Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Return Shipments';
                    RunObject = Page "Posted Return Shipments";
                    ToolTip = 'Open the list of posted return shipments.';
                }
                action("G/L Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Registers';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    ToolTip = 'View posted G/L entries.';
                }
            }
        }
        area(creation)
        {
            action("&Vendor")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Vendor';
                Image = Vendor;
                RunObject = Page "Vendor Card";
                RunPageMode = Create;
                ToolTip = 'Set up a new vendor from whom you buy goods or services. ';
            }
            action("&Purchase Order")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Purchase Order';
                Image = Document;
                RunObject = Page "Purchase Order";
                RunPageMode = Create;
                ToolTip = 'Purchase goods or services from a vendor.';
            }
            action("Purchase &Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase &Invoice';
                Image = NewPurchaseInvoice;
                RunObject = Page "Purchase Invoice";
                RunPageMode = Create;
                ToolTip = 'Create a new purchase invoice.';
            }
            action("Purchase Credit &Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Credit &Memo';
                Image = CreditMemo;
                RunObject = Page "Purchase Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Create a new purchase credit memo to revert a posted purchase invoice.';
            }
        }
        area(processing)
        {
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
            action("Payment &Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment &Journal';
                Image = PaymentJournal;
                RunObject = Page "Payment Journal";
                ToolTip = 'View or edit the payment journal where you can register payments to vendors.';
            }
            action("P&urchase Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'P&urchase Journal';
                Image = Journals;
                RunObject = Page "Purchase Journal";
                ToolTip = 'Post any purchase transaction for the vendor. ';
            }
            action(VendorPayments)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Vendor Payments';
                Image = SuggestVendorPayments;
                RunObject = Page "Vendor Ledger Entries";
                RunPageView = where("Document Type" = filter(Invoice),
                                    "Remaining Amount" = filter(< 0),
                                    "Applies-to ID" = filter(''));
                ToolTip = 'Opens vendor ledger entries for all vendors with invoices that have not been paid yet.';
            }
            action("Reconcile AP to GL")
            {
                Caption = 'Reconcile AP to GL';
                Image = "Report";
                RunObject = Report "Reconcile AP to GL";
                ToolTip = 'List all items that have been received on purchase orders, but for which you have not been invoiced. The value of these items is not reflected in the general ledger because the cost is unknown until they are invoiced. The report gives an estimated value of the purchase orders, you can use as an accrual to your general ledger.';
            }
            separator(Administration)
            {
                Caption = 'Administration';
                IsHeader = true;
            }
            action("Purchases && Payables &Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchases && Payables &Setup';
                Image = Setup;
                RunObject = Page "Purchases & Payables Setup";
                ToolTip = 'Define your general policies for purchase invoicing and returns, such as whether to require vendor invoice numbers and how to post purchase discounts. Set up your number series for creating vendors and different purchase documents.';
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
            separator(Customer)
            {
                Caption = 'Customer';
                IsHeader = true;
            }
            action("Credit Management")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Credit Management';
                Image = CustomerList;
                RunObject = Page "Customer List - Credit Mgmt.";
                ToolTip = 'View the customer list with credit limit.';
            }
            action("Order Status")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Order Status';
                Image = OrderList;
                RunObject = Page "Customer List - Order Status";
                ToolTip = 'View the customer list.';
            }
        }
    }
}
