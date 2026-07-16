// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Deposit;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Reports;
using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Reports;
using Microsoft.CashFlow.Setup;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Reports;
using Microsoft.CostAccounting.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Task;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
#if not CLEAN28
using Microsoft.Purchases.Reports;
#endif
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
#if not CLEAN28
using Microsoft.Sales.Reports;
#endif
using Microsoft.Sales.Setup;
using System.Threading;

page 9001 "Accounting Manager Role Center"
{
    Caption = 'Accounting Manager';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
                part(Control1902304208; "Account Manager Activities")
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
                part(Control99; "Finance Performance")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                part(Control103; "Trailing Sales Orders Chart")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                part(Control106; "My Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                part(Control100; "Cash Flow Forecast Chart")
                {
                    ApplicationArea = Basic, Suite;
                }
                part(Control1907692008; "My Customers")
                {
                    ApplicationArea = Basic, Suite;
                }
                part(Control1902476008; "My Vendors")
                {
                    ApplicationArea = Basic, Suite;
                }
                part(Control108; "Report Inbox Part")
                {
                    ApplicationArea = Basic, Suite;
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
            group("G/L Reports")
            {
                Caption = 'G/L Reports';
                action("Account G/L Turnover")
                {
                    Caption = 'Account G/L Turnover';
                    Image = Account;
                    RunObject = Report "Bank Account G/L Turnover";
                }
                action("Bank Account Card")
                {
                    Caption = 'Bank Account Card';
                    Image = BankAccount;
                    RunObject = Report "Bank Account Card";
                    ToolTip = 'View or edit information about the bank account.';
                }
                action("Cash Order Journal CO-3")
                {
                    Caption = 'Cash Order Journal CO-3';
                    Image = "Report";
                    RunObject = Report "Cash Order Journal CO-3";
                    ToolTip = 'View a report that shows the register of posted ingoing and outgoing cash orders during a specified reporting period. You can also specify the person who is responsible for the report. The person''s full name will be printed on the title page of the report. Typically, this report is created on a monthly basis.';
                }
                action("Cash Order Journal CO-4")
                {
                    Caption = 'Cash Order Journal CO-4';
                    Image = "Report";
                    RunObject = Report "Cash Report CO-4";
                    ToolTip = 'View a cash transactions report in standard format. The report shows the opening balance, all posted ingoing and outgoing cash orders, and the closing balance of an operational day for one cash account, per cashier. Russian accounting legislation requires that this report is run every day.';
                }
#if not CLEAN28
                action("&G/L Trial Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&G/L Trial Balance (Obsolete)';
                    Image = "Report";
                    RunObject = Report "Trial Balance";
                    ToolTip = 'View, print, or send a report that shows the balances for the general ledger accounts, including the debits and credits. You can use this report to ensure accurate accounting practices.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Trial Balance (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
                action("&Bank Detail Trial Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Bank Detail Trial Balance';
                    Image = "Report";
                    RunObject = Report "Bank Acc. - Detail Trial Bal.";
                    ToolTip = 'View, print, or send a report that shows a detailed trial balance for selected bank accounts. You can use the report at the close of an accounting period or fiscal year.';
                }
                action("&Account Schedule")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Account Schedule';
                    Image = "Report";
                    RunObject = Report "Account Schedule";
                    ToolTip = 'Open an account schedule to analyze figures in general ledger accounts or to compare general ledger entries with general ledger budget entries.';
                }
                action("Bu&dget")
                {
                    ApplicationArea = Suite;
                    Caption = 'Bu&dget';
                    Image = "Report";
                    RunObject = Report Budget;
                    ToolTip = 'View or edit estimated amounts for a range of accounting periods.';
                }
#if not CLEAN28
                action("Trial Bala&nce/Budget")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trial Bala&nce/Budget (Obsolete)';
                    Image = "Report";
                    RunObject = Report "Trial Balance/Budget";
                    ToolTip = 'View a trial balance in comparison to a budget. You can choose to see a trial balance for selected dimensions. You can use the report at the close of an accounting period or fiscal year.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Trial Balance/Budget (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
                action("Trial Balance by &Period")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trial Balance by &Period';
                    Image = "Report";
                    RunObject = Report "Trial Balance by Period";
                    ToolTip = 'Show the opening balance by general ledger account, the movements in the selected period of month, quarter, or year, and the resulting closing balance.';
                }
                action("&Fiscal Year Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Fiscal Year Balance';
                    Image = "Report";
                    RunObject = Report "Fiscal Year Balance";
                    ToolTip = 'View, print, or send a report that shows balance sheet movements for selected periods. The report shows the closing balance by the end of the previous fiscal year for the selected ledger accounts. It also shows the fiscal year until this date, the fiscal year by the end of the selected period, and the balance by the end of the selected period, excluding the closing entries. The report can be used at the close of an accounting period or fiscal year.';
                    Visible = false;
                }
                action("Balance Comp. - Prev. Y&ear")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance Comp. - Prev. Y&ear';
                    Image = "Report";
                    RunObject = Report "Balance Comp. - Prev. Year";
                    ToolTip = 'View a report that shows your company''s assets, liabilities, and equity compared to the previous year.';
                    Visible = false;
                }
                action("&Closing Trial Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Closing Trial Balance';
                    Image = "Report";
                    RunObject = Report "Closing Trial Balance";
                    ToolTip = 'View, print, or send a report that shows this year''s and last year''s figures as an ordinary trial balance. The closing of the income statement accounts is posted at the end of a fiscal year. The report can be used in connection with closing a fiscal year.';
                    Visible = false;
                }
            }
            action("G/L - VAT Reconciliation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L - VAT Reconciliation';
                Image = "Report";
                RunObject = Report "G/L - VAT Reconciliation";
                ToolTip = 'Verify that the VAT amounts on the VAT statements match the amounts from the G/L entries.';
            }
            group("Cash Flow")
            {
                Caption = 'Cash Flow';
                action("Cash Flow Date List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Date List';
                    Image = "Report";
                    RunObject = Report "Cash Flow Date List";
                    ToolTip = 'View forecast entries for a period of time that you specify. The registered cash flow forecast entries are organized by source types, such as receivables, sales orders, payables, and purchase orders. You specify the number of periods and their length.';
                }
            }
            group("Aged Accounts")
            {
                Caption = 'Aged Accounts';
#if not CLEAN28
                action("Aged Accounts &Receivable")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Aged Accounts &Receivable (Obsolete)';
                    Image = "Report";
                    RunObject = Report "Aged Accounts Receivable";
                    ToolTip = 'View an overview of when your receivables from customers are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Aged Accounts Receivable (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
                action("Aged Accounts Pa&yable")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Aged Accounts Pa&yable (Obsolete)';
                    Image = "Report";
                    RunObject = Report "Aged Accounts Payable";
                    ToolTip = 'View an overview of when your payables to vendors are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Aged Accounts Payable (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
                action("Reconcile Cus&t. and Vend. Accs")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reconcile Cus&t. and Vend. Accs';
                    Image = "Report";
                    RunObject = Report "Reconcile Cust. and Vend. Accs";
                    ToolTip = 'View if a certain general ledger account reconciles the balance on a certain date for the corresponding posting group. The report shows the accounts that are included in the reconciliation with the general ledger balance and the customer or the vendor ledger balance for each account and shows any differences between the general ledger balance and the customer or vendor ledger balance.';
                }
            }
            group(VAT)
            {
                Caption = 'VAT';
                action("Unrealized VAT Analysis")
                {
                    Caption = 'Unrealized VAT Analysis';
                    Image = Report2;
                    RunObject = Report "Unrealized VAT Analysis";
                    ToolTip = 'Analyze unrealized VAT amounts. ';
                }
                action("VAT Invoices Journal")
                {
                    Caption = 'VAT Invoices Journal';
                    Image = Excel;
                    RunObject = Report "VAT Invoices Journal";
                    ToolTip = 'Prepare to post import VAT with purchase invoices.';
                }
            }
            group("Cost Accounting")
            {
                Caption = 'Cost Accounting';
                action("Cost Accounting P/L Statement")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Accounting P/L Statement';
                    Image = "Report";
                    RunObject = Report "Cost Acctg. Statement";
                    ToolTip = 'View the credit and debit balances per cost type, together with the chart of cost types.';
                }
                action("CA P/L Statement per Period")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'CA P/L Statement per Period';
                    Image = "Report";
                    RunObject = Report "Cost Acctg. Stmt. per Period";
                    ToolTip = 'View profit and loss for cost types over two periods with the comparison as a percentage.';
                }
                action("CA P/L Statement with Budget")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'CA P/L Statement with Budget';
                    Image = "Report";
                    RunObject = Report "Cost Acctg. Statement/Budget";
                    ToolTip = 'View a comparison of the balance to the budget figures and calculates the variance and the percent variance in the current accounting period, the accumulated accounting period, and the fiscal year.';
                }
                action("Cost Accounting Analysis")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Accounting Analysis';
                    Image = "Report";
                    RunObject = Report "Cost Acctg. Analysis";
                    ToolTip = 'View balances per cost type with columns for seven fields for cost centers and cost objects. It is used as the cost distribution sheet in Cost accounting. The structure of the lines is based on the chart of cost types. You define up to seven cost centers and cost objects that appear as columns in the report.';
                }
            }
            group("G/L Correspondense")
            {
                Caption = 'G/L Correspondense';
                action("G/L Corresp. General Ledger")
                {
                    Caption = 'G/L Corresp. General Ledger';
                    Image = "Report";
                    RunObject = Report "G/L Corresp. General Ledger";
                    ToolTip = 'View general ledger correspondence entries.';
                }
                action("G/L Corresp. Journal Order")
                {
                    Caption = 'G/L Corresp. Journal Order';
                    Image = "Report";
                    RunObject = Report "G/L Corresp. Journal Order";
                    ToolTip = 'Prepare to post general ledger correspondence entries.';
                }
                action("G/L Corresp Entries Analysis")
                {
                    Caption = 'G/L Corresp Entries Analysis';
                    Image = "Report";
                    RunObject = Report "G/L Corresp Entries Analysis";
                    ToolTip = 'Analyze general ledger correspondence entries, including account debit and credit information.';
                }
            }
            group(Receivables)
            {
                Caption = 'Receivables';
                Image = Receivables;
                action("Customer Turnover")
                {
                    Caption = 'Customer Turnover';
                    Image = "Report";
                    RunObject = Report "Customer Turnover";
                }
                action("Customer Post. Gr. Turnover")
                {
                    Caption = 'Customer Post. Gr. Turnover';
                    Image = "Report";
                    RunObject = Report "Customer Post. Gr. Turnover";
                }
                action("Customer Entries Analysis")
                {
                    Caption = 'Customer Entries Analysis';
                    Image = "Report";
                    RunObject = Report "Customer Entries Analysis";
                }
            }
            group(Payables)
            {
                Caption = 'Payables';
                Image = Payables;
                action("Vendor Turnover")
                {
                    Caption = 'Vendor Turnover';
                    Image = "Report";
                    RunObject = Report "Vendor Turnover";
                    ToolTip = 'View the data about a vendor'' s entries for a specific period in the context of separate contracts or agreements.';
                }
                action("Vendor Post. Gr. Turnover")
                {
                    Caption = 'Vendor Post. Gr. Turnover';
                    Image = "Report";
                    RunObject = Report "Vendor Post. Gr. Turnover";
                    ToolTip = 'View vendors'' entries that are accumulated in the vendor posting groups.';
                }
                action("Vendor Entries Analysis")
                {
                    Caption = 'Vendor Entries Analysis';
                    Image = "Report";
                    RunObject = Report "Vendor Entries Analysis";
                    ToolTip = 'View vendors'' liabilities at the beginning and at the end of the period, entry analysis, and invoice discharging.';
                }
                action("Purch. without Vend. VAT Inv.")
                {
                    Caption = 'Purch. without Vend. VAT Inv.';
                    Image = "Report";
                    RunObject = Report "Purch. without Vend. VAT Inv.";
                }
            }
        }
        area(embedding)
        {
            action("Chart of Accounts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart of Accounts';
                RunObject = Page "Chart of Accounts";
                ToolTip = 'View the chart of accounts.';
            }
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
            action(Budgets)
            {
                ApplicationArea = Suite;
                Caption = 'Budgets';
                RunObject = Page "G/L Budget Names";
                ToolTip = 'View or edit estimated amounts for a range of accounting periods.';
            }
            action("Bank Accounts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Accounts';
                Image = BankAccount;
                RunObject = Page "Bank Account List";
                ToolTip = 'View or set up detailed information about your bank account, such as which currency to use, the format of bank files that you import and export as electronic payments, and the numbering of checks.';
            }
            action(BankDeposit)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Deposit';
                Image = DepositSlip;
                RunObject = codeunit "Open Deposits Page";
                ToolTip = 'Create a new bank deposit.';
            }
            action(Items)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action(Customers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customers';
                Image = Customer;
                RunObject = Page "Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action(CustomersBalance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance';
                Image = Balance;
                RunObject = Page "Customer List";
                RunPageView = where("Balance (LCY)" = filter(<> 0));
                ToolTip = 'View a summary of the bank account balance in different periods.';
            }
            action("Sales Orders")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Orders';
                Image = "Order";
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
            }
            action(Reminders)
            {
                ApplicationArea = Suite;
                Caption = 'Reminders';
                Image = Reminder;
                RunObject = Page "Reminder List";
                ToolTip = 'Remind customers about overdue amounts based on reminder terms and the related reminder levels. Each reminder level includes rules about when the reminder will be issued in relation to the invoice due date or the date of the previous reminder and whether interests are added. Reminders are integrated with finance charge memos, which are documents informing customers of interests or other money penalties for payment delays.';
            }
            action("Finance Charge Memos")
            {
                ApplicationArea = Suite;
                Caption = 'Finance Charge Memos';
                Image = FinChargeMemo;
                RunObject = Page "Finance Charge Memo List";
                ToolTip = 'Send finance charge memos to customers with delayed payments, typically following a reminder process. Finance charges are calculated automatically and added to the overdue amounts on the customer''s account according to the specified finance charge terms and penalty/interest amounts.';
            }
            action("Incoming Documents")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Incoming Documents';
                Image = Documents;
                RunObject = Page "Incoming Documents";
                ToolTip = 'Handle incoming documents, such as vendor invoices in PDF or as image files, that you can manually or automatically convert to document records, such as purchase invoices. The external files that represent incoming documents can be attached at any process stage, including to posted documents and to the resulting vendor, customer, and general ledger entries.';
            }
            action("G/L Correspondence Analysis")
            {
                Caption = 'G/L Correspondence Analysis';
                RunObject = Page "G/L Correspondence Analysis";
                ToolTip = 'Analyze general ledger correspondence entries, including account debit and credit information.';
            }
            action("Statutory Reports")
            {
                Caption = 'Statutory Reports';
                RunObject = Page "Statutory Reports";
                ToolTip = 'View or edit reports that you use to import and export data for electronic tax reporting and other required documents.';
            }
            action("EC Sales List")
            {
                ApplicationArea = BasicEU;
                Caption = 'EC Sales List';
                RunObject = Page "EC Sales List Reports";
                ToolTip = 'Prepare the EC Sales List report so you can submit VAT amounts to a tax authority.';
            }
        }
        area(sections)
        {
            group(Journals)
            {
                Caption = 'Journals';
                Image = Journals;
                action(PurchaseJournals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(Purchases),
                                        Recurring = const(false));
                    ToolTip = 'Post any purchase-related transaction directly to a vendor, bank, or general ledger account instead of using dedicated documents. You can post all types of financial purchase transactions, including payments, refunds, and finance charge amounts. Note that you cannot post item quantities with a purchase journal.';
                }
                action(SalesJournals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(Sales),
                                        Recurring = const(false));
                    ToolTip = 'Post any sales-related transaction directly to a customer, bank, or general ledger account instead of using dedicated documents. You can post all types of financial sales transactions, including payments, refunds, and finance charge amounts. Note that you cannot post item quantities with a sales journal.';
                }
                action(CashReceiptJournals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Receipt Journals';
                    Image = Journals;
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const("Cash Receipts"),
                                        Recurring = const(false));
                    ToolTip = 'Register received payments by manually applying them to the related customer, vendor, or bank ledger entries. Then, post the payments to G/L accounts and thereby close the related ledger entries.';
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
                action(ICGeneralJournals)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'IC General Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(Intercompany),
                                        Recurring = const(false));
                    ToolTip = 'Post intercompany transactions. IC general journal lines must contain either an IC partner account or a customer or vendor account that has been assigned an intercompany partner code.';
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
                action("Invent. Act List")
                {
                    Caption = 'Invent. Act List';
                    RunObject = Page "Invent. Act List";
                    ToolTip = 'View an inventory of contractor payables and receivables.';
                }
            }
            group("Fixed Assets")
            {
                Caption = 'Fixed Assets';
                Image = FixedAssets;
                action(Action17)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets';
                    RunObject = Page "Fixed Asset List";
                    ToolTip = 'Manage periodic depreciation of your machinery or machines, keep track of your maintenance costs, manage insurance policies related to fixed assets, and monitor fixed asset statistics.';
                }
                action(Insurance)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Insurance';
                    RunObject = Page "Insurance List";
                    ToolTip = 'Manage insurance policies for fixed assets and monitor insurance coverage.';
                }
                action("Fixed Assets G/L Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets G/L Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(Assets),
                                        Recurring = const(false));
                    ToolTip = 'Post fixed asset transactions, such as acquisition and depreciation, in integration with the general ledger. The FA G/L Journal is a general journal, which is integrated into the general ledger.';
                }
                action("Fixed Assets Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Journals';
                    RunObject = Page "FA Journal Batches";
                    RunPageView = where(Recurring = const(false));
                    ToolTip = 'Post fixed asset transactions, such as acquisition and depreciation book without integration to the general ledger.';
                }
                action("Fixed Assets Reclass. Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Reclass. Journals';
                    RunObject = Page "FA Reclass. Journal Batches";
                    ToolTip = 'Transfer, split, or combine fixed assets by preparing reclassification entries to be posted in the fixed asset journal.';
                }
                action("Insurance Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Insurance Journals';
                    RunObject = Page "Insurance Journal Batches";
                    ToolTip = 'Post entries to the insurance coverage ledger.';
                }
                action("<Action3>")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Recurring General Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(General),
                                        Recurring = const(true));
                    ToolTip = 'Define how to post transactions that recur with few or no changes to general ledger, bank, customer, vendor, or fixed asset accounts';
                }
                action("Recurring Fixed Asset Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Recurring Fixed Asset Journals';
                    RunObject = Page "FA Journal Batches";
                    RunPageView = where(Recurring = const(true));
                    ToolTip = 'Post recurring fixed asset transactions, such as acquisition and depreciation book without integration to the general ledger.';
                }
            }
            group(Action121)
            {
                Caption = 'Cash Flow';
                action("Cash Flow Forecasts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Forecasts';
                    RunObject = Page "Cash Flow Forecast List";
                    ToolTip = 'Combine various financial data sources to find out when a cash surplus or deficit might happen or whether you should pay down debt, or borrow to meet upcoming expenses.';
                }
                action("Chart of Cash Flow Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chart of Cash Flow Accounts';
                    RunObject = Page "Chart of Cash Flow Accounts";
                    ToolTip = 'View a chart contain a graphical representation of one or more cash flow accounts and one or more cash flow setups for the included general ledger, purchase, sales, services, or fixed assets accounts.';
                }
                action("Cash Flow Manual Revenues")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Revenues';
                    RunObject = Page "Cash Flow Manual Revenues";
                    ToolTip = 'Record manual revenues, such as rental income, interest from financial assets, or new private capital to be used in cash flow forecasting.';
                }
                action("Cash Flow Manual Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Expenses';
                    RunObject = Page "Cash Flow Manual Expenses";
                    ToolTip = 'Record manual expenses, such as salaries, interest on credit, or planned investments to be used in cash flow forecasting.';
                }
            }
            group(Action84)
            {
                Caption = 'Cost Accounting';
                action("Cost Types")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Types';
                    RunObject = Page "Chart of Cost Types";
                    ToolTip = 'View the chart of cost types with a structure and functionality that resembles the general ledger chart of accounts. You can transfer the general ledger income statement accounts or create your own chart of cost types.';
                }
                action("Cost Centers")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Centers';
                    RunObject = Page "Chart of Cost Centers";
                    ToolTip = 'Manage cost centers, which are departments and profit centers that are responsible for costs and income. Often, there are more cost centers set up in cost accounting than in any dimension that is set up in the general ledger. In the general ledger, usually only the first level cost centers for direct costs and the initial costs are used. In cost accounting, additional cost centers are created for additional allocation levels.';
                }
                action("Cost Objects")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Objects';
                    RunObject = Page "Chart of Cost Objects";
                    ToolTip = 'Set up cost objects, which are products, product groups, or services of a company. These are the finished goods of a company that carry the costs. You can link cost centers to departments and cost objects to projects in your company.';
                }
                action("Cost Allocations")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Allocations';
                    RunObject = Page "Cost Allocation Sources";
                    ToolTip = 'Manage allocation rules to allocate costs and revenues between cost types, cost centers, and cost objects. Each allocation consists of an allocation source and one or more allocation targets. For example, all costs for the cost type Electricity and Heating are an allocation source. You want to allocate the costs to the cost centers Workshop, Production, and Sales, which are three allocation targets.';
                }
                action("Cost Budgets")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Budgets';
                    RunObject = Page "Cost Budget Names";
                    ToolTip = 'Set up cost accounting budgets that are created based on cost types just as a budget for the general ledger is created based on general ledger accounts. A cost budget is created for a certain period of time, for example, a fiscal year. You can create as many cost budgets as needed. You can create a new cost budget manually, or by importing a cost budget, or by copying an existing cost budget as the budget base.';
                }
                action("FA Release Acts")
                {
                    Caption = 'FA Release Acts';
                    RunObject = Page "FA Document List";
                    RunPageView = where("Document Type" = const(Release));
                    ToolTip = 'Document the sale of a fixed asset to other organization as a fixed asset itself and to transfer information of the fixed asset history to the new owner. The document is used for confirmation of the acceptance and delivery of the fixed asset.';
                }
                action("FA Movement Acts")
                {
                    Caption = 'FA Movement Acts';
                    RunObject = Page "FA Document List";
                    RunPageView = where("Document Type" = const(Movement));
                    ToolTip = 'Track the movement of fixed assets and record the status of your fixed assets.';
                }
                action("FA Writeoff Acts")
                {
                    Caption = 'FA Writeoff Acts';
                    RunObject = Page "FA Document List";
                    RunPageView = where("Document Type" = const(Writeoff));
                    ToolTip = 'View the full or partial write-off of fixed assets.';
                }
            }
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                action("Posted Sales Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Invoices';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Invoices";
                    ToolTip = 'Open the list of posted sales invoices.';
                }
                action("Posted Sales Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Credit Memos';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Credit Memos";
                    ToolTip = 'Open the list of posted sales credit memos.';
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
                action("Issued Reminders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Issued Reminders';
                    Image = OrderReminder;
                    RunObject = Page "Issued Reminder List";
                    ToolTip = 'View the list of issued reminders.';
                }
                action("Issued Fin. Charge Memos")
                {
                    ApplicationArea = Suite;
                    Caption = 'Issued Fin. Charge Memos';
                    Image = PostedMemo;
                    RunObject = Page "Issued Fin. Charge Memo List";
                    ToolTip = 'View the list of issued finance charge memos.';
                }
                action("G/L Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Registers';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    ToolTip = 'View posted G/L entries.';
                }
                action("Cost Accounting Registers")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Accounting Registers';
                    RunObject = Page "Cost Registers";
                    ToolTip = 'Get an overview of all cost entries sorted by posting date. ';
                }
                action("Cost Accounting Budget Registers")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Accounting Budget Registers';
                    RunObject = Page "Cost Budget Registers";
                    ToolTip = 'Get an overview of all cost budget entries sorted by posting date. ';
                }
                action("Posted FA Release Acts")
                {
                    Caption = 'Posted FA Release Acts';
                    RunObject = Page "Posted FA Document List";
                    RunPageView = where("Document Type" = const(Release));
                    ToolTip = 'Open the list of posted fixed asset releases.';
                }
                action("Posted FA Writeoff Acts")
                {
                    Caption = 'Posted FA Writeoff Acts';
                    RunObject = Page "Posted FA Document List";
                    RunPageView = where("Document Type" = const(Writeoff));
                    ToolTip = 'Open the list of posted fixed asset write-offs.';
                }
                action("Posted FA Movement Acts")
                {
                    Caption = 'Posted FA Movement Acts';
                    RunObject = Page "Posted FA Document List";
                    RunPageView = where("Document Type" = const(Movement));
                    ToolTip = 'Open the list of posted fixed asset movements.';
                }
                action("Posted Invt. Receipts")
                {
                    Caption = 'Posted Invt. Receipts';
                    RunObject = Page "Posted Invt. Receipts";
                    ToolTip = 'Open the list of posted receipts.';
                }
                action("Posted Invt. Shipment")
                {
                    Caption = 'Posted Invy. Shipment';
                    RunObject = Page "Posted Invt. Shipments";
                    ToolTip = 'Open the list of posted shipments.';
                }
                action("Tax Difference Registers")
                {
                    Caption = 'Tax Difference Registers';
                    RunObject = Page "Tax Difference Registers";
                    ToolTip = 'View posted tax difference transactions with all the income or expense codes. ';
                }
                action("Posted Bank Deposits")
                {
                    Caption = 'Posted Bank Deposits';
                    Image = PostedDeposit;
                    RunObject = codeunit "Open P. Bank Deposits L. Page";
                    ToolTip = 'View the posted bank deposit header, bank deposit header lines, bank deposit comments, and bank deposit dimensions.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                Image = Administration;
                action(Currencies)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currencies';
                    Image = Currency;
                    RunObject = Page Currencies;
                    ToolTip = 'View the different currencies that you trade in or update the exchange rates by getting the latest rates from an external service provider.';
                }
                action("Accounting Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Periods';
                    Image = AccountingPeriods;
                    RunObject = Page "Accounting Periods";
                    ToolTip = 'Set up the number of accounting periods, such as 12 monthly periods, within the fiscal year and specify which period is the start of the new fiscal year.';
                }
                action("Number Series")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number Series';
                    RunObject = Page "No. Series";
                    ToolTip = 'View or edit the number series that are used to organize transactions';
                }
                action("Analysis Views")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Analysis Views';
                    RunObject = Page "Analysis View List";
                    ToolTip = 'Analyze amounts in your general ledger by their dimensions using analysis views that you have set up.';
                }
                action("Account Schedules")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Financial Reporting';
                    RunObject = Page "Financial Reports";
                    ToolTip = 'Get insight into the financial data stored in your chart of accounts. Financial reports analyze figures in G/L accounts, and compare general ledger entries with general ledger budget entries. For example, you can view the general ledger entries as percentages of the budget entries. Financial reports provide the data for core financial statements and views, such as the Cash Flow chart.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Bank Account Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Posting Groups';
                    RunObject = Page "Bank Account Posting Groups";
                    ToolTip = 'Set up posting groups, so that payments in and out of each bank account are posted to the specified general ledger account.';
                }
                action("Bank Directory List")
                {
                    Caption = 'Bank Directory List';
                    RunObject = Page "Bank Directory List";
                }
                action("Bank Account Details")
                {
                    Caption = 'Bank Account Details';
                    RunObject = Page "Bank Account Details";
                    ToolTip = 'View or edit information about the bank account.';
                }
                action("FA Charge List")
                {
                    Caption = 'FA Charge List';
                    RunObject = Page "FA Charge List";
                    ToolTip = 'View the list of fixed asset charges that are used to include additional charges on the purchase of fixed assets in the fixed asset acquisition cost.';
                }
                action("Norm Jurisdictions")
                {
                    Caption = 'Norm Jurisdictions';
                    RunObject = Page "Tax Reg. Norm Jurisdictions";
                    ToolTip = 'View the norm jurisdictions that are set up to calculate taxable profits and losses in tax accounting. You can use the Norm Jurisdictions window to set up and define norm jurisdictions that can be used when you calculate tax differences. Norm jurisdictions are based on Russian tax laws that define a variety of tax rates. ';
                }
                action("OKATO Codes")
                {
                    Caption = 'OKATO Codes';
                    RunObject = Page "OKATO Codes";
                    ToolTip = 'View or edit the standard classification codes of the districts that are used for statistical and tax purposes. This information is imported from external sources, but you can also enter it manually.';
                }
                action("Agreement Groups")
                {
                    Caption = 'Agreement Groups';
                    RunObject = Page "Agreement Groups";
                }
                action("Default Signature Setup")
                {
                    Caption = 'Default Signature Setup';
                    RunObject = Page "Default Signature Setup";
                }
                action("Excel Templates")
                {
                    Caption = 'Excel Templates';
                    RunObject = Page "Excel Templates";
                    ToolTip = 'View or edit the Excel templates that are used for statutory reporting.';
                }
            }
            group("Tax Accounting")
            {
                Caption = 'Tax Accounting';
                action("Tax Authorities")
                {
                    Caption = 'Tax Authorities';
                    RunObject = Page "Vendor List";
                    RunPageView = where("Vendor Type" = const("Tax Authority"));
                    ToolTip = 'View or edit detailed information about the related tax authority.';
                }
                action("Future Period Expenses")
                {
                    Caption = 'Future Period Expenses';
                    RunObject = Page "Fixed Asset List";
                    RunPageView = where("FA Type" = const("Future Expense"));
                    ToolTip = 'Post expenses to a special account on a monthly basis. These future expenses are later included as expenses. VAT is deducted when future expenses are included in current expenses.';
                }
                action("VAT Purchase Ledgers")
                {
                    Caption = 'VAT Purchase Ledgers';
                    RunObject = Page "VAT Purchase Ledgers";
                    ToolTip = 'View or edit VAT ledgers for purchases to store details about VAT in transactions that involve goods and services in Russia or goods imported into Russia.';
                }
                action("VAT Sales Ledgers")
                {
                    Caption = 'VAT Sales Ledgers';
                    RunObject = Page "VAT Sales Ledgers";
                    ToolTip = 'View or edit VAT ledgers for sales to store details about VAT in transactions that involve goods and services in Russia or goods imported into Russia.';
                }
                action("VAT Settlement Journal")
                {
                    Caption = 'VAT Settlement Journal';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const("VAT Settlement"),
                                        Recurring = const(false));
                    ToolTip = 'Prepare to post VAT settlements. ';
                }
                action("VAT Reinstatement Journal")
                {
                    Caption = 'VAT Reinstatement Journal';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const("VAT Reinstatement"),
                                        Recurring = const(false));
                    ToolTip = 'Post VAT reinstatements. ';
                }
                action("Tax Difference Journal")
                {
                    Caption = 'Tax Difference Journal';
                    RunObject = Page "Tax Difference Journal Batches";
                    ToolTip = 'Create and post tax difference transactions. Tax differences are variations in tax amounts caused by the different rules for recognizing income and expenses between entries for book accounting and tax accounting.';
                }
                action("Future Expenses Journals")
                {
                    Caption = 'Future Expenses Journals';
                    RunObject = Page "General Journal Batches";
                    RunPageView = where("Template Type" = const(General),
                                        Recurring = const(false));
                    ToolTip = 'Post expenses to a special account on a monthly basis. These future expenses are later included as expenses. VAT is deducted when future expenses are included in current expenses.';
                }
                action("Tax Differences")
                {
                    Caption = 'Tax Differences';
                    RunObject = Page "Tax Differences";
                    ToolTip = 'View or edit the tax differences that make up variations in tax amounts caused by the different rules for recognizing income and expenses between entries for book accounting and tax accounting.';
                }
                action("Tax Calc. Section List")
                {
                    Caption = 'Tax Calc. Section List';
                    RunObject = Page "Tax Calc. Section List";
                    ToolTip = 'View or edit tax calculation sections that are used to calculate taxable profits and losses.';
                }
            }
        }
        area(creation)
        {
            action("Sales &Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales &Credit Memo';
                Image = CreditMemo;
                RunObject = Page "Sales Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Create a new sales credit memo to revert a posted sales invoice.';
            }
            action("P&urchase Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'P&urchase Credit Memo';
                Image = CreditMemo;
                RunObject = Page "Purchase Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Create a new purchase credit memo so you can manage returned items to a vendor.';
            }
        }
        area(processing)
        {
            group(Payments)
            {
                Caption = 'Payments';
                action("Cas&h Receipt Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cas&h Receipt Journal';
                    Image = CashReceiptJournal;
                    RunObject = Page "Cash Receipt Journal";
                    ToolTip = 'Apply received payments to the related non-posted sales documents.';
                }
                action("Pa&yment Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pa&yment Journal';
                    Image = PaymentJournal;
                    RunObject = Page "Payment Journal";
                    ToolTip = 'Make payments to vendors.';
                }
                action("Bank Account R&econciliation")
                {
                    Caption = 'Bank Account R&econciliation';
                    Image = BankAccountRec;
                    RunObject = Page "Bank Acc. Reconciliation";
                    ToolTip = 'View the entries and the balance on your bank accounts against a statement from the bank.';
                }
                action("Import Currency Exch. Rate")
                {
                    Caption = 'Import Currency Exch. Rate';
                    Image = CurrencyExchangeRates;
                    RunObject = Report "Import Currency Exch. Rate";
                    ToolTip = 'Update currency exchange rates.';
                }
                action("Payment Reconciliation Journals")
                {
                    Caption = 'Payment Reconciliation Journals';
                    Image = ApplyEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Pmt. Reconciliation Journals";
                    RunPageMode = View;
                }
                action("Adjust E&xchange Rates")
                {
                    Caption = 'Adjust E&xchange Rates';
                    Ellipsis = true;
                    Image = AdjustExchangeRates;
                    RunObject = Codeunit "Exch. Rate Adjmt. Run Handler";
                    ToolTip = 'Adjust exchange rates and create adjustment transactions for customers, vendors, and bank accounts. You can also set up separate dimension values for profit and loss adjustment transactions. You can then use the test mode to preview the adjustments without posting transactions.';
                }
                action("C&reate Reminders")
                {
                    Caption = 'C&reate Reminders';
                    Ellipsis = true;
                    Image = CreateReminders;
                    RunObject = Report "Create Reminders";
                }
                action("Create Finance Charge &Memos")
                {
                    Caption = 'Create Finance Charge &Memos';
                    Ellipsis = true;
                    Image = CreateFinanceChargememo;
                    RunObject = Report "Create Finance Charge Memos";
                }
            }
            group(Action67)
            {
                Caption = 'VAT';
                action("VAT Settlement Worksheet")
                {
                    Caption = 'VAT Settlement Worksheet';
                    Image = VATLedger;
                    RunObject = Page "VAT Settlement Worksheet";
                    ToolTip = 'Plan which VAT amounts to settle. You must report the volume of your trade with European Union (EU) countries/regions to the tax authorities, even if no amount has to be settled.';
                }
                action("VAT Reinstatement Worksheet")
                {
                    Caption = 'VAT Reinstatement Worksheet';
                    Image = VATLedger;
                    RunObject = Page "VAT Reinstatement Worksheet";
                    ToolTip = 'Plan which VAT reinstatements to include in VAT ledgers.';
                }
                action("Calc. and Pos&t VAT Settlement")
                {
                    Caption = 'Calc. and Pos&t VAT Settlement';
                    Image = SettleOpenTransactions;
                    RunObject = Report "Calc. and Post VAT Settlement";
                    ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account. For every VAT posting group, the batch job finds all the VAT entries in the VAT Entry table that are included in the filters in the definition window.';
                    Visible = false;
                }
            }
            group(Analysis)
            {
                Caption = 'Analysis';
                action("Analysis &Views")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Analysis &Views';
                    Image = AnalysisView;
                    RunObject = Page "Analysis View List";
                    ToolTip = 'Analyze amounts in your general ledger by their dimensions using analysis views that you have set up.';
                }
            }
            group(Action1210042)
            {
                Caption = 'Fixed Assets';
                action("Calculate Deprec&iation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate Deprec&iation';
                    Ellipsis = true;
                    Image = CalculateDepreciation;
                    RunObject = Report "Calculate Depreciation";
                }
            }
            group(Consolidation)
            {
                Caption = 'Consolidation';
                action("Import Co&nsolidation from Database")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Co&nsolidation from Database';
                    Ellipsis = true;
                    Image = ImportDatabase;
                    RunObject = Report "Import Consolidation from DB";
                    ToolTip = 'Import entries from the business units that will be included in a consolidation. You can use the batch job if the business unit comes from the same database in Business Central as the consolidated company.';
                }
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                action("P&ost Inventory Cost to G/L")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost Inventory Cost to G/L';
                    Image = PostInventoryToGL;
                    RunObject = Report "Post Inventory Cost to G/L";
                }
            }
            group(Turnovers)
            {
                Caption = 'Turnovers';
                action("G/L Turnover")
                {
                    Caption = 'G/L Turnover';
                    Image = Turnover;
                    RunObject = Page "G/L Account Turnover";
                    ToolTip = 'Analyze the turnover compared with vendor or customer account balances.';
                }
                action(Action1210025)
                {
                    Caption = 'Customer Turnover';
                    Image = Turnover;
                    RunObject = Page "Customer G/L Turnover";
                }
                action(Action1210026)
                {
                    Caption = 'Vendor Turnover';
                    Image = Turnover;
                    RunObject = Page "Vendor G/L Turnover";
                    ToolTip = 'View the data about a vendor'' s entries for a specific period in the context of separate contracts or agreements.';
                }
                action("FA Turnover")
                {
                    Caption = 'FA Turnover';
                    Image = Turnover;
                    RunObject = Page "FA G/L Turnover";
                    ToolTip = 'View fixed asset turnover information. You can view information such as the fixed asset name, quantity, status, depreciation dates, and amounts. The report can be used as documentation for the correction of quantities and for auditing purposes.';
                }
            }
            group(Action1210028)
            {
                Caption = 'Statutory Reports';
                action(Action1210031)
                {
                    Caption = 'Statutory Reports';
                    Image = "Report";
                    RunObject = Page "Statutory Reports";
                    ToolTip = 'View or edit reports that you use to import and export data for electronic tax reporting and other required documents.';
                }
                action("Tax Register Sections")
                {
                    Caption = 'Tax Register Sections';
                    Image = Register;
                    RunObject = Page "Tax Register Sections";
                    ToolTip = 'View or edit the sections that help you create the components and calculations required to track taxable profit and losses in tax registers.';
                }
                action(Action1210035)
                {
                    Caption = 'Tax Calc. Section List';
                    Image = List;
                    RunObject = Page "Tax Calc. Section List";
                    ToolTip = 'View or edit tax calculation sections that are used to calculate taxable profits and losses.';
                }
            }
            group(Action80)
            {
                Caption = 'Administration';
                action("General &Ledger Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General &Ledger Setup';
                    Image = Setup;
                    RunObject = Page "General Ledger Setup";
                    ToolTip = 'Post financial transactions directly to general ledger accounts and other accounts, such as bank, customer, vendor, and employee accounts. Posting with a general journal always creates entries on general ledger accounts. This is true even when, for example, you post a journal line to a customer account, because an entry is posted to a general ledger receivables account through a posting group.';
                }
                action("&Sales && Receivables Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Sales && Receivables Setup';
                    Image = Setup;
                    RunObject = Page "Sales & Receivables Setup";
                    ToolTip = 'Define your general policies for sales invoicing and returns, such as when to show credit and stockout warnings and how to post sales discounts. Set up your number series for creating customers and different sales documents.';
                }
                action("&Purchases && Payables Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Purchases && Payables Setup';
                    Image = Setup;
                    RunObject = Page "Purchases & Payables Setup";
                    ToolTip = 'Define your general policies for purchase invoicing and returns, such as whether to require vendor invoice numbers and how to post purchase discounts. Set up your number series for creating vendors and different purchase documents.';
                }
                action("&Fixed Asset Setup")
                {
                    ApplicationArea = FixedAssets;
                    Caption = '&Fixed Asset Setup';
                    Image = Setup;
                    RunObject = Page "Fixed Asset Setup";
                    ToolTip = 'Define your accounting policies for fixed assets, such as the allowed posting period and whether to allow posting to main assets. Set up your number series for creating new fixed assets.';
                }
                action("Cash Flow Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Setup';
                    Image = CashFlowSetup;
                    RunObject = Page "Cash Flow Setup";
                    ToolTip = 'Set up the accounts where cash flow figures for sales, purchase, and fixed-asset transactions are stored.';
                }
                action("Cost Accounting Setup")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Accounting Setup';
                    Image = CostAccountingSetup;
                    RunObject = Page "Cost Accounting Setup";
                    ToolTip = 'Specify how you transfer general ledger entries to cost accounting, how you link dimensions to cost centers and cost objects, and how you handle the allocation ID and allocation document number.';
                }
            }
            group(History)
            {
                Caption = 'History';
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

