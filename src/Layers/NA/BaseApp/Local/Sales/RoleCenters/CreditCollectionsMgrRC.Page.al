// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.RoleCenters;

using Microsoft.Bank.Deposit;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Reports;
using System.Automation;

page 36603 "Credit & Collections Mgr. RC"
{
    Caption = 'Credit & Collections Manager', Comment = 'Use same translation as ''Profile Description'' ';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            group(Control1900724808)
            {
                ShowCaption = false;
                part(Control1905739008; "Credit Manager Activities")
                {
                }
            }
            group(Control1900724708)
            {
                ShowCaption = false;
                part(Control1907692008; "My Customers")
                {
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Customer Listing")
            {
                Caption = 'Customer Listing';
                RunObject = Report "Customer Listing";
                ToolTip = 'View customers in a list format. You can use this report to display all customers or include only customers with outstanding balance amounts.';
            }
            action("Customer Balance to Date")
            {
                Caption = 'Customer Balance to Date';
                RunObject = Report "Customer - Balance to Date";
                ToolTip = 'View a detailed balance for selected customers. The report can, for example, be used at the close of an accounting period or fiscal year.';
            }
            action("Aged Accounts Receivable")
            {
                Caption = 'Aged Accounts Receivable';
                Image = "Report";
                RunObject = Report "Aged Accounts Receivable NA";
                ToolTip = 'View, print, or save an overview of when customer payments are due or overdue, divided into four periods.';
            }
            action("Customer Account Detail")
            {
                Caption = 'Customer Account Detail';
                RunObject = Report "Customer Account Detail";
                ToolTip = 'View the detailed account activity for each customer for any period of time. The report lists all activity with running account balances, or only open items or only closed items with totals of either. The report can also show the application of payments to invoices.';
            }
            separator(Action20)
            {
            }
            action("Cash Applied")
            {
                Caption = 'Cash Applied';
                RunObject = Report "Cash Applied";
                ToolTip = 'View how the cash received from customers has been applied to documents. The report includes the number of the document and type of document to which the payment has been applied.';
            }
            action("Projected Cash Payments")
            {
                Caption = 'Projected Cash Payments';
                RunObject = Report "Projected Cash Payments";
                ToolTip = 'View projections about what future payments to vendors will be. Current orders are used to generate a chart, using the specified time period and start date, to break down future payments. The report also includes a total balance column.';
            }
        }
        area(embedding)
        {
            action(Approvals)
            {
                Caption = 'Approvals';
                Image = Approvals;
                RunObject = Page "Approval Entries";
                ToolTip = 'View the list of documents that await approval.';
            }
            action(Customers)
            {
                Caption = 'Customers';
                RunObject = Page "Customer List - Collections";
                ToolTip = 'View the list of customers.';
            }
            action(Balance)
            {
                Caption = 'Balance';
                Image = Balance;
                RunObject = Page "Customer List - Collections";
                RunPageView = where("Balance on Date (LCY)" = filter(> 0));
                ToolTip = 'View a detailed balance for selected customers. The report can, for example, be used at the close of an accounting period or fiscal year.';
            }
            action("Unlimited Credit")
            {
                Caption = 'Unlimited Credit';
                RunObject = Page "Customer List - Collections";
                RunPageView = where("Credit Limit (LCY)" = const(0));
                ToolTip = 'View a customer''s available credit and how it is calculated. If the available credit is 0 and the customer''s credit limit is also 0, then the customer has unlimited credit because no credit limit has been defined.';
            }
            action("Limited Credit")
            {
                Caption = 'Limited Credit';
                RunObject = Page "Customer List - Collections";
                RunPageView = where("Credit Limit (LCY)" = filter(<> 0));
                ToolTip = 'View customers'' remaining amount available to use for payments. It is calculated as follows: Credit Limit = Balance - Min. Balance - Total Amount on Payments';
            }
            action("Invoices by Due Date")
            {
                Caption = 'Invoices by Due Date';
                RunObject = Page "Customer Ledger Entries";
                RunPageView = sorting(Open, "Due Date")
                              where(Open = const(true),
                                    "Document Type" = filter(Invoice | "Credit Memo"));
                ToolTip = 'View the list of outstanding invoices by their payment due date.';
            }
            action("Sales Orders")
            {
                Caption = 'Sales Orders';
                RunObject = Page "Customer Order Header Status";
                ToolTip = 'View the list of ongoing sales orders.';
            }
            action("Sales Return Orders")
            {
                Caption = 'Sales Return Orders';
                RunObject = Page "Customer Order Header Status";
                RunPageView = where("Document Type" = const("Return Order"));
                ToolTip = 'View the list of ongoing sales return orders.';
            }
            action("Sales Invoices")
            {
                Caption = 'Sales Invoices';
                RunObject = Page "Sales Invoice List";
                ToolTip = 'View the list of ongoing sales invoices.';
            }
            action(Reminders)
            {
                Caption = 'Reminders';
                Image = Reminder;
                RunObject = Page "Reminder List";
                ToolTip = 'View the list of ongoing reminders.';
            }
            action("Finance Charge Memos")
            {
                Caption = 'Finance Charge Memos';
                Image = FinChargeMemo;
                RunObject = Page "Finance Charge Memo List";
                ToolTip = 'View the list of ongoing finance charge memos.';
            }
        }
        area(sections)
        {
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                action("Posted Sales Shipments")
                {
                    Caption = 'Posted Sales Shipments';
                    RunObject = Page "Posted Sales Shipments";
                    ToolTip = 'Open the list of posted sales shipments.';
                }
                action("Posted Sales Invoices")
                {
                    Caption = 'Posted Sales Invoices';
                    RunObject = Page "Posted Sales Invoices";
                    ToolTip = 'Open the list of posted sales invoices.';
                }
                action("Posted Return Receipts")
                {
                    Caption = 'Posted Return Receipts';
                    RunObject = Page "Posted Return Receipts";
                    ToolTip = 'Open the list of posted return receipts.';
                }
                action("Posted Sales Credit Memos")
                {
                    Caption = 'Posted Sales Credit Memos';
                    RunObject = Page "Posted Sales Credit Memos";
                    ToolTip = 'Open the list of posted sales credit memos.';
                }
                action("Issued Reminders")
                {
                    Caption = 'Issued Reminders';
                    Image = OrderReminder;
                    RunObject = Page "Issued Reminder List";
                    ToolTip = 'View the list of issued reminders.';
                }
                action("Issued Fin. Charge Memos")
                {
                    Caption = 'Issued Fin. Charge Memos';
                    RunObject = Page "Issued Fin. Charge Memo List";
                    ToolTip = 'View the list of issued finance charge memos.';
                }
                action("Posted Deposits")
                {
                    Caption = 'Posted Deposits';
                    RunObject = Page "Posted Deposit List";
                    ToolTip = 'View the posted deposit header, deposit header lines, deposit comments, and deposit dimensions.';
                }
                action("Posted Bank Deposits")
                {
                    Caption = 'Posted Bank Deposits';
                    RunObject = codeunit "Open P. Bank Deposits L. Page";
                    ToolTip = 'View the posted bank deposit header, bank deposit header lines, bank deposit comments, and bank deposit dimensions.';
                }
            }
        }
        area(processing)
        {
            separator(New)
            {
                Caption = 'New';
                IsHeader = true;
            }
            action("Fin. Charge Memo")
            {
                Caption = 'Fin. Charge Memo';
                RunObject = Page "Finance Charge Memo";
                ToolTip = 'Create a new finance charge memo to fine a customer for late payment.';
            }
            action(Reminder)
            {
                Caption = 'Reminder';
                Image = Reminder;
                RunObject = Page Reminder;
                ToolTip = 'Create a new reminder to remind a customer of overdue payment.';
            }
        }
    }
}

