// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Payment;
using Microsoft.Sales.Customer;
using Microsoft.Foundation.Task;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Reports;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Bank.DirectDebit;
using Microsoft.Sales.Setup;
using System.Visualization;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Bank.Reconciliation;
using Microsoft.Foundation.Navigate;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.RoleCenters;
using Microsoft.EServices.EDocument;

page 9077 "Account Receivables"
{
    PageType = RoleCenter;
    layout
    {
        area(RoleCenter)
        {
            part(Headline; "Headline RC Accountant")
            {
                ApplicationArea = All;
            }
            part("Account Receivables KPIs"; "Account Receivables KPIs")
            {
                ApplicationArea = All;
            }
            part("Acc. Receivable Activities"; "Acc. Receivable Activities")
            {
                ApplicationArea = All;
            }
            part("Reminder Cues"; "Reminder Cues")
            {
                ApplicationArea = All;
            }
            part("User Task Activities"; "User Tasks Activities")
            {
                ApplicationArea = All;
            }
            part(SelfService; "Team Member Activities No Msgs")
            {
                ApplicationArea = Suite;
            }
            part("Overdue Customers"; "Overdue Customers")
            {
                ApplicationArea = All;
            }
            systempart(MyNotes; MyNotes)
            {
                ApplicationArea = All;
            }
            part(ReportInbox; "Report Inbox Part")
            {
                AccessByPermission = TableData "Report Inbox" = IMD;
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        #region Navigation menus
        area(sections)
        {
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                action("Posted Sales Shipments")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Sales Shipments';
                    Image = PostedShipment;
                    RunObject = Page "Posted Sales Shipments";
                    ToolTip = 'Open the list of posted sales shipments.';
                }
                action("Posted Sales Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Sales Invoices';
                    Image = PostedShipment;
                    RunObject = Page "Posted Sales Invoices";
                    ToolTip = 'Open the list of posted sales invoices.';
                }
                action("Posted Return Receipts")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Return Receipts';
                    Image = PostedReturnReceipt;
                    RunObject = Page "Posted Return Receipts";
                    ToolTip = 'Open the list of posted return receipts.';
                }
                action("Posted Sales Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Sales Credit Memos';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Credit Memos";
                    ToolTip = 'Open the list of posted sales credit memos.';
                }
                action("G/L Registers")
                {
                    ApplicationArea = All;
                    Caption = 'G/L Registers';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    ToolTip = 'View auditing details for all general ledger entries. Every time an entry is posted, a register is created in which you can see the first and last number of its entries in order to document when entries were posted.';
                }
            }
            group("Sales Documents")
            {
                action("Sales Quotes")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Quotes';
                    RunObject = page "Sales Quotes";
                }
                action("Sales Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Orders';
                    RunObject = page "Sales Order List";
                }
                action("Sales Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Invoices';
                    RunObject = page "Sales Invoice List";
                }
                action("Sales Credit Memos")
                {
                    ApplicationArea = All;
                    RunObject = page "Sales Credit Memos";
                }
            }
            group("Reminder Documents")
            {
                action(Reminders)
                {
                    ApplicationArea = All;
                    Caption = 'Reminders';
                    Image = Reminder;
                    RunObject = Page "Reminder List";
                    ToolTip = 'Remind customers about overdue amounts based on reminder terms and the related reminder levels. Each reminder level includes rules about when the reminder will be issued in relation to the invoice due date or the date of the previous reminder and whether interests are added. Reminders are integrated with finance charge memos, which are documents informing customers of interests or other money penalties for payment delays.';
                }
                action("Finance Charge Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Finance Charge Memos';
                    Image = FinChargeMemo;
                    RunObject = page "Finance Charge Memo List";
                    ToolTip = 'Send finance charge memos to customers with delayed payments, typically following a reminder process. Finance charges are calculated automatically and added to the overdue amounts on the customer';
                }
                action("Issued Reminders")
                {
                    ApplicationArea = All;
                    Caption = 'Issued Reminders';
                    Image = OrderReminder;
                    RunObject = Page "Issued Reminder List";
                    ToolTip = 'View the list of issued reminders.';
                }
                action("Issued Finance Charge Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Issued Finance Charge Memos';
                    Image = FinChargeMemo;
                    RunObject = page "Issued Fin. Charge Memo List";
                    ToolTip = 'View the list of issued finance charge memos.';
                }
            }
            group(Reports)
            {
                action("C&ustomer - List")
                {
                    ApplicationArea = All;
                    Caption = 'C&ustomer - List';
                    Image = "Report";
                    RunObject = Report "Customer - List";
                    ToolTip = 'View various information for customers, such as customer posting group, discount group, finance charge and payment information, salesperson, the customer''s default currency and credit limit (in LCY), and the customer''s current balance (in LCY).';
                }
                action("Customer - &Balance to Date")
                {
                    ApplicationArea = All;
                    Caption = 'Customer - &Balance to Date';
                    Image = "Report";
                    RunObject = Report "Customer - Balance to Date";
                    ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
                }
                action("Aged &Accounts Receivable")
                {
                    ApplicationArea = All;
                    Caption = 'Aged &Accounts Receivable';
                    Image = "Report";
                    RunObject = Report "Aged Accounts Receivable";
                    ToolTip = 'View an overview of when your receivables from customers are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
                }
                action("Customer - &Summary Aging Simp.")
                {
                    ApplicationArea = Suite;
                    Caption = 'Customer - &Summary Aging Simp.';
                    Image = "Report";
                    RunObject = Report "Customer - Summary Aging Simp.";
                    ToolTip = 'View, print, or save a summary of each customer''s total payments due, divided into three time periods. The report can be used to decide when to issue reminders, to evaluate a customer''s creditworthiness, or to prepare liquidity analyses.';
                }
                action("Customer - Trial Balan&ce")
                {
                    ApplicationArea = All;
                    Caption = 'Customer - Trial Balan&ce';
                    Image = "Report";
                    RunObject = Report "Customer - Trial Balance";
                    ToolTip = 'View the beginning and ending balance for customers with entries within a specified period. The report can be used to verify that the balance for a customer posting group is equal to the balance on the corresponding general ledger account on a certain date.';
                }
                action("Cus&tomer/Item Sales")
                {
                    ApplicationArea = All;
                    Caption = 'Cus&tomer/Item Sales';
                    Image = "Report";
                    RunObject = Report "Customer/Item Sales";
                    ToolTip = 'View a list of item sales for each customer during a selected time period. The report contains information on quantity, sales amount, profit, and possible discounts. It can be used, for example, to analyze a company''s customer groups.';
                }
                action("Create Recurring Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Create Recurring Invoices';
                    Ellipsis = true;
                    Image = CreateDocument;
                    RunObject = Report "Create Recurring Sales Inv.";
                    ToolTip = 'Create sales invoices according to standard sales lines that are assigned to the customers and with posting dates within the valid-from and valid-to dates that you specify on the standard sales code. Can also be used for SEPA direct debit. ';
                }
                action("Reconcile Customer and &Vendor Accounts")
                {
                    ApplicationArea = All;
                    Caption = 'Reconcile Customer and &Vendor Accounts';
                    Image = "Report";
                    RunObject = Report "Reconcile Cust. and Vend. Accs";
                    ToolTip = 'View if a certain general ledger account reconciles the balance on a certain date for the corresponding posting group. The report shows the accounts that are included in the reconciliation with the general ledger balance and the customer or the vendor ledger balance for each account and shows any differences between the general ledger balance and the customer or vendor ledger balance.';
                }
            }
        }
        #endregion
        #region Navigation bar actions
        area(Embedding)
        {
            action("Customers")
            {
                ApplicationArea = All;
                RunObject = page "Customer List";
                ToolTip = 'View the list of customers.';
            }
            action(CustomersBalance)
            {
                ApplicationArea = All;
                Caption = 'Balance';
                Image = Balance;
                RunObject = Page "Customer List";
                RunPageView = where("Balance (LCY)" = filter(<> 0));
                ToolTip = 'View a summary of the bank account balance in different periods.';
            }
            action("Sales Orders_Embedding")
            {
                ApplicationArea = All;
                Caption = 'Sales Orders';
                Image = "Order";
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
            }
            action("Sales Invoices_Embedding")
            {
                ApplicationArea = All;
                Caption = 'Sales Invoices';
                Image = Invoice;
                RunObject = Page "Sales Invoice List";
                ToolTip = 'Register your sales to customers and invite them to pay according to the delivery and payment terms by sending them a sales invoice document. Posting a sales invoice registers shipment and records an open receivable entry on the customer''s account, which will be closed when payment is received. To manage the shipment process, use sales orders, in which sales invoicing is integrated.';
            }
            action("Sales Return Orders")
            {
                ApplicationArea = All;
                Caption = 'Sales Return Orders';
                Image = ReturnOrder;
                RunObject = Page "Sales Return Order List";
                ToolTip = 'Compensate your customers for incorrect or damaged items that you sent to them and received payment for. Sales return orders enable you to receive items from multiple sales documents with one sales return, automatically create related sales credit memos or other return-related documents, such as a replacement sales order, and support warehouse documents for the item handling. Note: If an erroneous sale has not been paid yet, you can simply cancel the posted sales invoice to automatically revert the financial transaction.';
            }
        }
        #endregion
        #region Action bar
        area(Processing)
        {
            separator(New)
            {
                Caption = 'New';
                IsHeader = true;
            }
            action("C&ustomer")
            {
                ApplicationArea = All;
                Caption = 'Create C&ustomer';
                Image = Customer;
                RunObject = Page "Customer Card";
                RunPageMode = Create;
                ToolTip = 'Create a new customer card.';
            }
            action(PaymentRegistration)
            {
                ApplicationArea = All;
                Caption = 'Register Customer Payments';
                Image = Payment;
                RunObject = Page "Payment Registration";
                ToolTip = 'Process your customer payments by matching amounts received on your bank account with the related unpaid sales invoices, and then post the payments.';
            }
            group("&Sales")
            {
                Caption = 'Create &Sales Documents';
                Image = Sales;
                action("Sales &Order")
                {
                    ApplicationArea = All;
                    Caption = 'Sales &Order';
                    Image = Document;
                    RunObject = Page "Sales Order";
                    RunPageMode = Create;
                    ToolTip = 'Create a new sales order for items or services.';
                }
                action("Sales &Invoice")
                {
                    ApplicationArea = All;
                    Caption = 'Sales &Invoice';
                    Image = NewSalesInvoice;
                    RunObject = Page "Sales Invoice";
                    RunPageMode = Create;
                    ToolTip = 'Create a new invoice for the sales of items or services. Invoice quantities cannot be posted partially.';
                }
                action("Sales &Credit Memo")
                {
                    ApplicationArea = All;
                    Caption = 'Sales &Credit Memo';
                    Image = CreditMemo;
                    RunObject = Page "Sales Credit Memo";
                    RunPageMode = Create;
                    ToolTip = 'Create a new sales credit memo to revert a posted sales invoice.';
                }
            }
            action("Create &Reminder")
            {
                ApplicationArea = All;
                Caption = 'Create &Reminder';
                Image = Reminder;
                RunObject = Page Reminder;
                RunPageMode = Create;
                ToolTip = 'Create a new reminder for a customer who has overdue payments.';
            }
            action("Direct Debit Collections")
            {
                ApplicationArea = All;
                Caption = 'Direct Debit Collections';
                RunObject = Page "Direct Debit Collections";
                ToolTip = 'Instruct your bank to withdraw payment amounts from your customer''s bank account and transfer them to your company''s account. A direct debit collection holds information about the customer''s bank account, the affected sales invoices, and the customer''s agreement, the so-called direct-debit mandate. From the resulting direct-debit collection entry, you can then export an XML file that you send or upload to your bank for processing.';
            }
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
            action("Cash Receipt &Journal")
            {
                ApplicationArea = All;
                Caption = 'Cash Receipt &Journal';
                Image = CashReceiptJournal;
                RunObject = Page "Cash Receipt Journal";
                ToolTip = 'Open the cash receipt journal to post incoming payments.';
            }
            action("Payment Reconciliation Journals")
            {
                ApplicationArea = All;
                Caption = 'Payment Reconciliation Journals';
                Image = ApplyEntries;
                RunObject = Page "Pmt. Reconciliation Journals";
                RunPageMode = View;
                ToolTip = 'Reconcile unpaid documents automatically with their related bank transactions by importing a bank statement feed or file. In the payment reconciliation journal, incoming or outgoing payments on your bank are automatically, or semi-automatically, applied to their related open customer or vendor ledger entries. Any open bank account ledger entries related to the applied customer or vendor ledger entries will be closed when you choose the Post Payments and Reconcile Bank Account action. This means that the bank account is automatically reconciled for payments that you post with the journal.';
            }
            action("General Journals")
            {
                ApplicationArea = All;
                Caption = 'General Journals';
                Image = Journal;
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(General),
                                        Recurring = const(false));
                ToolTip = 'Post financial transactions directly to general ledger accounts and other accounts, such as bank, customer, vendor, and employee accounts. Posting with a general journal always creates entries on general ledger accounts. This is true even when, for example, you post a journal line to a customer account, because an entry is posted to a general ledger receivables account through a posting group.';
            }
            action("Navi&gate")
            {
                ApplicationArea = All;
                Caption = 'Find entries...';
                Image = Navigate;
                RunObject = Page Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
            }
            separator(Action111)
            {
            }
            separator(Administration)
            {
                Caption = 'Administration';
                IsHeader = true;
            }
            action("General Ledger Setup")
            {
                ApplicationArea = All;
                RunObject = page "General Ledger Setup";
                ToolTip = 'Configure the setup used for the General Journal.';
            }
            action("Sales && Recei&vables Setup")
            {
                ApplicationArea = All;
                Caption = 'Sales && Recei&vables Setup';
                Image = Setup;
                RunObject = Page "Sales & Receivables Setup";
                ToolTip = 'Define your general policies for sales invoicing and returns, such as when to show credit and stockout warnings and how to post sales discounts. Set up your number series for creating customers and different sales documents.';
            }
        }

        #endregion
    }
}
