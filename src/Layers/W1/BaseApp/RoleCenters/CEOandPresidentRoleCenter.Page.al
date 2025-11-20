// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.CashFlow.Forecast;
using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.RoleCenters;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Reports;
using Microsoft.Sales.RoleCenters;
using System.Threading;

page 9019 "CEO and President Role Center"
{
    Caption = 'President';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control21; "Finance Performance")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control4; "Finance Performance")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part(Control1907692008; "My Customers")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control24; "Cash Flow Forecast Chart")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control27; "Sales Performance")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control28; "Sales Performance")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part(Control29; "Report Inbox Part")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control25; "My Job Queue")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part(Control1902476008; "My Vendors")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part(Control1905989608; "My Items")
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

    actions
    {
        area(reporting)
        {
            action("Recei&vables-Payables")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recei&vables-Payables';
                Image = ReceivablesPayables;
                RunObject = Report "Receivables-Payables";
                ToolTip = 'Perform bookkeeping tasks.';
            }
            action("&Trial Balance/Budget")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Trial Balance/Budget';
                Image = "Report";
                RunObject = Report "Trial Balance/Budget";
                ToolTip = 'View a trial balance in comparison to a budget. You can choose to see a trial balance for selected dimensions. You can use the report at the close of an accounting period or fiscal year.';
            }
            action("&Closing Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Closing Trial Balance';
                Image = "Report";
                RunObject = Report "Closing Trial Balance";
                ToolTip = 'View, print, or send a report that shows this year''s and last year''s figures as an ordinary trial balance. The closing of the income statement accounts is posted at the end of a fiscal year. The report can be used in connection with closing a fiscal year.';
            }
            action("&Fiscal Year Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Fiscal Year Balance';
                Image = "Report";
                RunObject = Report "Fiscal Year Balance";
                ToolTip = 'View, print, or send a report that shows balance sheet movements for selected periods. The report shows the closing balance by the end of the previous fiscal year for the selected ledger accounts. It also shows the fiscal year until this date, the fiscal year by the end of the selected period, and the balance by the end of the selected period, excluding the closing entries. The report can be used at the close of an accounting period or fiscal year.';
            }
            separator(Action6)
            {
            }
            action("Customer - &Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - &Balance';
                Image = "Report";
                RunObject = Report "Customer - Balance to Date";
                ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
            }
            action("Customer - T&op 10 List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - T&op 10 List';
                Image = "Report";
                RunObject = Report "Customer - Top 10 List";
                ToolTip = 'View which customers purchase the most or owe the most in a selected period. Only customers that have either purchases during the period or a balance at the end of the period will be included.';
            }
            action("Customer - S&ales List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - S&ales List';
                Image = "Report";
                RunObject = Report "Customer - Sales List";
                ToolTip = 'View customer sales for a period, for example, to report sales activity to customs and tax authorities. You can choose to include only customers with total sales that exceed a minimum amount. You can also specify whether you want the report to show address details for each customer.';
            }
            action("Sales &Statistics")
            {
                ApplicationArea = Suite;
                Caption = 'Sales &Statistics';
                Image = "Report";
                RunObject = Report "Sales Statistics";
                ToolTip = 'View customers'' total costs, sales, and profits over time, for example, to analyze earnings trends. The report shows amounts for original and adjusted costs, sales, profits, invoice discounts, payment discounts, and profit percentage in three adjustable periods.';
            }
            separator(Action11)
            {
            }
            action("Vendor - &Purchase List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - &Purchase List';
                Image = "Report";
                RunObject = Report "Vendor - Purchase List";
                ToolTip = 'View a list of your purchases in a period, for example, to report purchase activity to customs and tax authorities.';
            }
        }
        area(embedding)
        {
            action("Account Schedules")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Financial Reporting';
                RunObject = Page "Financial Reports";
                ToolTip = 'Get insight into the financial data stored in your chart of accounts. Financial reports analyze figures in G/L accounts, and compare general ledger entries with general ledger budget entries. For example, you can view the general ledger entries as percentages of the budget entries. Financial reports provide the data for core financial statements and views, such as the Cash Flow chart.';
            }
            action("Analysis by Dimensions")
            {
                ApplicationArea = Dimensions;
                Caption = 'Analysis by Dimensions';
                Image = AnalysisViewDimension;
                RunObject = Page "Analysis View List";
                ToolTip = 'View amounts in G/L accounts by their dimension values and other filters that you define in an analysis view and then show in a matrix window.';
            }
            action("Sales Analysis Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Analysis Report';
                RunObject = Page "Analysis Report Sale";
                RunPageView = where("Analysis Area" = filter(Sales));
                ToolTip = 'Analyze the dynamics of your sales according to key sales performance indicators that you select, for example, sales turnover in both amounts and quantities, contribution margin, or progress of actual sales against the budget. You can also use the report to analyze your average sales prices and evaluate the sales performance of your sales force.';
            }
            action(Budgets)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Budgets';
                RunObject = Page "G/L Budget Names";
                ToolTip = 'View or edit estimated amounts for a range of accounting periods.';
            }
            action("Sales Budgets")
            {
                ApplicationArea = SalesBudget;
                Caption = 'Sales Budgets';
                RunObject = Page "Item Budget Names";
                RunPageView = where("Analysis Area" = filter(Sales));
                ToolTip = 'Enter item sales values of type amount, quantity, or cost for expected item sales in different time periods. You can create sales budgets by items, customers, customer groups, or other dimensions in your business. The resulting sales budgets can be reviewed here or they can be used in comparisons with actual sales data in sales analysis reports.';
            }
            action("Sales Quotes")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Quotes';
                Image = Quote;
                RunObject = Page "Sales Quotes";
                ToolTip = 'Make offers to customers to sell certain products on certain delivery and payment terms. While you negotiate with a customer, you can change and resend the sales quote as much as needed. When the customer accepts the offer, you convert the sales quote to a sales invoice or a sales order in which you process the sale.';
            }
            action("Sales Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Orders';
                Image = "Order";
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
            }
            action("Sales Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Invoices';
                Image = Invoice;
                RunObject = Page "Sales Invoice List";
                ToolTip = 'Register your sales to customers and invite them to pay according to the delivery and payment terms by sending them a sales invoice document. Posting a sales invoice registers shipment and records an open receivable entry on the customer''s account, which will be closed when payment is received. To manage the shipment process, use sales orders, in which sales invoicing is integrated.';
            }
            action(Customers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customers';
                Image = Customer;
                RunObject = Page "Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action(Contacts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Contacts';
                Image = CustomerContact;
                RunObject = Page "Contact List";
                ToolTip = 'View a list of all your contacts.';
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
        area(sections)
        {
        }
    }
}
