// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Deposit;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Reports;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Task;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
#if not CLEAN28
using Microsoft.Purchases.Reports;
#endif
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
#if not CLEAN28
using Microsoft.Sales.Reports;
#endif
using Microsoft.Sales.Setup;
using System.Automation;
using System.Threading;

page 9004 "Bookkeeper Role Center"
{
    Caption = 'Bookkeeper';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control1901197008; "Bookkeeper Activities")
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
            part(ApprovalsActivities; "Approvals Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control1907692008; "My Customers")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control17; "My Job Queue")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part(Control1902476008; "My Vendors")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control18; "Report Inbox Part")
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
            action("A&ccount Schedule")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'A&ccount Schedule';
                Image = "Report";
                RunObject = Report "Account Schedule";
                ToolTip = 'Analyze figures in general ledger accounts or compare general ledger entries with general ledger budget entries. For example, you can view the G/L entries as percentages of the budget entries. You use the Account Schedule window to set up account schedules.';
            }
            group("&Trial Balance")
            {
                Caption = '&Trial Balance';
                Image = Balance;
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
                action("Bank &Detail Trial Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank &Detail Trial Balance';
                    Image = "Report";
                    RunObject = Report "Bank Acc. - Detail Trial Bal.";
                    ToolTip = 'View transactions for all bank accounts with subtotals per account. Each account shows the opening balance on the first line, the list of transactions for the account and a closing balance on the last line.';
                }
#if not CLEAN28
                action("T&rial Balance/Budget")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'T&rial Balance/Budget (Obsolete)';
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
                action("Closing Tria&l Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closing Tria&l Balance';
                    Image = "Report";
                    RunObject = Report "Closing Trial Balance";
                    ToolTip = 'View this year''s and last year''s figures as an ordinary trial balance. For income statement accounts, the balances are shown without closing entries. Closing entries are listed on a fictitious date that falls between the last day of one fiscal year and the first day of the next one. The closing of the income statement accounts is posted at the end of a fiscal year. The report can be used in connection with closing a fiscal year.';
                }
            }
            action("&Fiscal Year Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Fiscal Year Balance';
                Image = "Report";
                RunObject = Report "Fiscal Year Balance";
                ToolTip = 'View, print, or send a report that shows balance sheet movements for selected periods. The report shows the closing balance by the end of the previous fiscal year for the selected ledger accounts. It also shows the fiscal year until this date, the fiscal year by the end of the selected period, and the balance by the end of the selected period, excluding the closing entries. The report can be used at the close of an accounting period or fiscal year.';
            }
            action("Balance C&omp. . Prev. Year")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance C&omp. . Prev. Year';
                Image = "Report";
                RunObject = Report "Balance Comp. - Prev. Year";
                ToolTip = 'View a report that shows your company''s assets, liabilities, and equity compared to the previous year.';
            }
            group("Aged Accounts")
            {
                Caption = 'Aged Accounts';
#if not CLEAN28
                action("&Aged Accounts Receivable")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Aged Accounts Receivable';
                    Image = "Report";
                    RunObject = Report "Aged Accounts Receivable";
                    ToolTip = 'View overdue customer payments.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
                action("Aged Accou&nts Payable")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Aged Accou&nts Payable';
                    Image = "Report";
                    RunObject = Report "Aged Accounts Payable";
                    ToolTip = 'View an overview of when your payables to vendors are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report is obsolete and will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
                action("Reconcile Customer and &Vendor Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reconcile Customer and &Vendor Accounts';
                    Image = "Report";
                    RunObject = Report "Reconcile Cust. and Vend. Accs";
                    ToolTip = 'View if a certain general ledger account reconciles the balance on a certain date for the corresponding posting group. The report shows the accounts that are included in the reconciliation with the general ledger balance and the customer or the vendor ledger balance for each account and shows any differences between the general ledger balance and the customer or vendor ledger balance.';
                }
            }
            group(VAT)
            {
                Caption = 'VAT';
                action("VAT Invoices Journal")
                {
                    Caption = 'VAT Invoices Journal';
                    Image = Excel;
                    RunObject = Report "VAT Invoices Journal";
                    ToolTip = 'Prepare to post import VAT with purchase invoices.';
                }
                action("Unrealized VAT Analysis")
                {
                    Caption = 'Unrealized VAT Analysis';
                    Image = Report2;
                    RunObject = Report "Unrealized VAT Analysis";
                    ToolTip = 'Analyze unrealized VAT amounts. ';
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
            group("Bank Accounts")
            {
                Caption = 'Bank Accounts';
                action("Bank Account G/L Turnover")
                {
                    Caption = 'Bank Account G/L Turnover';
                    Image = "Report";
                    RunObject = Report "Bank Account G/L Turnover";
                    ToolTip = 'View a report that shows the bank account general ledger turnover for a period of time. The information includes debit and credit amounts for a starting period, and net change amounts for a period or starting period. This report is useful for correcting general ledger turnover information and for auditing purposes.';
                }
                action("Bank Account Card")
                {
                    Caption = 'Bank Account Card';
                    Image = "Report";
                    RunObject = Report "Bank Account Card";
                    ToolTip = 'View or edit information about the bank account.';
                }
                action("G/L - VAT Reconciliation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L - VAT Reconciliation';
                    Image = "Report";
                    RunObject = Report "G/L - VAT Reconciliation";
                    ToolTip = 'Verify that the VAT amounts on the VAT statements match the amounts from the G/L entries.';
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
            }
            group(Action1210068)
            {
                Caption = 'Customers';
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
            group(Action1210069)
            {
                Caption = 'Vendors';
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
            ToolTip = 'Collect and make payments, prepare statements, and manage reminders.';
            action("Chart of Accounts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart of Accounts';
                RunObject = Page "Chart of Accounts";
                ToolTip = 'View the chart of accounts.';
            }
            action(Action63)
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
            action(VendorsPaymentonHold)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment on Hold';
                RunObject = Page "Vendor List";
                RunPageView = where(Blocked = filter(Payment));
                ToolTip = 'View a list of all vendor ledger entries on which the On Hold field is marked.';
            }
            action("VAT Statements")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Statements';
                RunObject = Page "VAT Statement Names";
                ToolTip = 'View a statement of posted VAT amounts, calculate your VAT settlement amount for a certain period, such as a quarter, and prepare to send the settlement to the tax authorities.';
                Visible = false;
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
            action("Purchase Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Invoices';
                RunObject = Page "Purchase Invoices";
                ToolTip = 'Create purchase invoices to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase invoices dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase invoices can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
            }
            action("Purchase Orders")
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Orders';
                RunObject = Page "Purchase Order List";
                ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
            }
            action("Sales Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Invoices';
                Image = Invoice;
                RunObject = Page "Sales Invoice List";
                ToolTip = 'Register your sales to customers and invite them to pay according to the delivery and payment terms by sending them a sales invoice document. Posting a sales invoice registers shipment and records an open receivable entry on the customer''s account, which will be closed when payment is received. To manage the shipment process, use sales orders, in which sales invoicing is integrated.';
            }
            action("Sales Orders")
            {
                ApplicationArea = Suite;
                Caption = 'Sales Orders';
                Image = "Order";
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
            }
            action("Advance Statements")
            {
                Caption = 'Advance Statements';
                RunObject = Page "Purchase Advance Reports";
                ToolTip = 'View information about payments made to and from responsible employees. This report also enables you to print and view primary documents of responsible employee expenses.';
            }
            action("Cash Order Journals")
            {
                Caption = 'Cash Order Journals';
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const("Cash Order Payments"),
                                    Recurring = const(false));
            }
            action(Approvals)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Approvals';
                Image = Approvals;
                RunObject = Page "Requests to Approve";
                ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';
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
                Visible = false;
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
            action(RecurringGeneralJournals)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recurring General Journals';
                RunObject = Page "General Journal Batches";
                RunPageView = where("Template Type" = const(General),
                                    Recurring = const(true));
                ToolTip = 'Define how to post transactions that recur with few or no changes to general ledger, bank, customer, vendor, or fixed asset accounts';
            }
            action("G/L Correspondence Analysis")
            {
                Caption = 'G/L Correspondence Analysis';
                RunObject = Page "G/L Correspondence Analysis";
                ToolTip = 'Analyze general ledger correspondence entries, including account debit and credit information.';
            }
            action("Letter of Attorney List")
            {
                Caption = 'Letter of Attorney List';
                RunObject = Page "Letter of Attorney List";
                ToolTip = 'View the list of documents that authorize individuals or organizations to act on the behalf of another to perform certain processes.';
            }
            action(Open)
            {
                Caption = 'Open';
                Image = Edit;
                RunObject = Page "Letter of Attorney List";
                RunPageView = where(Status = const(Open));
                ShortCutKey = 'Return';
            }
            action(Released)
            {
                Caption = 'Released';
                RunObject = Page "Letter of Attorney List";
                RunPageView = where(Status = const(Released));
                ToolTip = 'View the list of released documents that are ready for the next stage of processing.';
            }
        }
        area(sections)
        {
            group("Fixed Assets")
            {
                Caption = 'Fixed Assets';
                action(Action1210011)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets';
                    RunObject = Page "Fixed Asset List";
                    ToolTip = 'View the list of fixed assets.';
                }
                action(Insurance)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Insurance';
                    RunObject = Page "Insurance List";
                    ToolTip = 'View fixed asset insurance information.';
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
                    ToolTip = 'Prepare to update fixed asset insurance information.';
                }
                action("Recurring Fixed Asset Journals")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Recurring Fixed Asset Journals';
                    RunObject = Page "FA Journal Batches";
                    RunPageView = where(Recurring = const(true));
                    ToolTip = 'Post recurring fixed asset transactions, such as acquisition and depreciation book without integration to the general ledger.';
                }
                action("FA Release Acts")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Release Acts';
                    RunObject = Page "FA Document List";
                    RunPageView = where("Document Type" = const(Release));
                    ToolTip = 'Document the sale of a fixed asset to other organization as a fixed asset itself and to transfer information of the fixed asset history to the new owner. The document is used for confirmation of the acceptance and delivery of the fixed asset.';
                }
                action("FA Movement Acts")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Movement Acts';
                    RunObject = Page "FA Document List";
                    RunPageView = where("Document Type" = const(Movement));
                    ToolTip = 'Track the movement of fixed assets and record the status of your fixed assets.';
                }
                action("FA Writeoff Acts")
                {
                    ApplicationArea = FixedAssets;
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
                ToolTip = 'View posted invoices and credit memos, and analyze G/L registers.';
                action("Posted Sales Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Shipments';
                    Image = PostedShipment;
                    RunObject = Page "Posted Sales Shipments";
                    ToolTip = 'Open the list of posted sales shipments.';
                }
                action("Posted Sales Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Invoices';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Invoices";
                    ToolTip = 'Open the list of posted sales invoices.';
                }
                action("Posted Return Receipts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Return Receipts';
                    Image = PostedReturnReceipt;
                    RunObject = Page "Posted Return Receipts";
                    ToolTip = 'Open the list of posted return receipts.';
                }
                action("Posted Sales Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Credit Memos';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Credit Memos";
                    ToolTip = 'Open the list of posted sales credit memos.';
                }
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
                action("Posted Return Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Return Shipments';
                    RunObject = Page "Posted Return Shipments";
                    ToolTip = 'Open the list of posted return shipments.';
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
                action("Issued Fi. Charge Memos")
                {
                    ApplicationArea = Suite;
                    Caption = 'Issued Fi. Charge Memos';
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
                action("Posted FA Release Acts")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Posted FA Release Acts';
                    RunObject = Page "Posted FA Document List";
                    RunPageView = where("Document Type" = const(Release));
                    ToolTip = 'Open the list of posted fixed asset releases.';
                }
                action("Posted FA Writeoff Acts")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Posted FA Writeoff Acts';
                    RunObject = Page "Posted FA Document List";
                    RunPageView = where("Document Type" = const(Writeoff));
                    ToolTip = 'Open the list of posted fixed asset write-offs.';
                }
                action("Posted FA Movement Acts")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Posted FA Movement Acts';
                    RunObject = Page "Posted FA Document List";
                    RunPageView = where("Document Type" = const(Movement));
                    ToolTip = 'Open the list of posted fixed asset movements.';
                }
                action("Posted Invt. Receipts")
                {
                    Caption = 'Posted Inventory Receipts';
                    RunObject = Page "Posted Invt. Receipts";
                    ToolTip = 'Open the list of posted inventory receipts.';
                }
                action("Posted Invt. Shipment")
                {
                    Caption = 'Posted Inventory Shipment';
                    RunObject = Page "Posted Invt. Shipments";
                    ToolTip = 'Open the list of posted inventory shipments.';
                }
                action("Posted Bank Deposit List")
                {
                    Caption = 'Posted Bank Deposit List';
                    RunObject = codeunit "Open P. Bank Deposits L. Page";
                    ToolTip = 'View the posted bank deposit header, bank deposit header lines, bank deposit comments, and bank deposit dimensions.';
                }
            }
            group(Action22)
            {
                Caption = 'Approvals';
                ToolTip = 'Request approval of your documents, cards, or journal lines or, as the approver, approve requests made by other users.';
                action("Requests Sent for Approval")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Requests Sent for Approval';
                    Image = Approvals;
                    RunObject = Page "Approval Entries";
                    RunPageView = where(Status = filter(Open));
                    ToolTip = 'View the approval requests that you have sent.';
                }
                action(RequestsToApprove)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Requests to Approve';
                    Image = Approvals;
                    RunObject = Page "Requests to Approve";
                    ToolTip = 'Accept or reject other users'' requests to create or change certain documents, cards, or journal lines that you must approve before they can proceed. The list is filtered to requests where you are set up as the approver.';
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
                action("Default Signature Setup")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Default Signature Setup';
                    RunObject = Page "Default Signature Setup";
                }
                action("FA Charge List")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Charge List';
                    RunObject = Page "FA Charge List";
                    ToolTip = 'View the list of fixed asset charges that are used to include additional charges on the purchase of fixed assets in the fixed asset acquisition cost.';
                }
                action("Excel Templates")
                {
                    Caption = 'Excel Templates';
                    RunObject = Page "Excel Templates";
                    ToolTip = 'View or edit the Excel templates that are used for statutory reporting.';
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                action("Item List")
                {
                    Caption = 'Item List';
                    RunObject = Page "Item List";
                    ToolTip = 'View the list of items that you trade with.';
                }
                action("Item Journal Batches")
                {
                    Caption = 'Item Journal Batches';
                    RunObject = Page "Item Journal Batches";
                    ToolTip = 'View the journal batches, personalized journal layouts, that users use to post item transactions.';
                }
                action("Inventory Receipts")
                {
                    Caption = 'Inventory Receipts';
                    RunObject = Page "Invt. Document List";
                    RunPageView = where("Document Type" = const(Receipt));
                    ToolTip = 'View the list of inventory receipts.';
                }
                action("Inventory Shipments")
                {
                    Caption = 'Inventory Shipments';
                    RunObject = Page "Invt. Document List";
                    RunPageView = where("Document Type" = const(Shipment));
                    ToolTip = 'View the list of inventory shipments.';
                }
            }
        }
        area(creation)
        {
            group(Receivables)
            {
                Caption = 'Receivables';
                Image = Receivables;
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageMode = Create;
                    ToolTip = 'Create a new customer card.';
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
                action("Sales Credit &Memo")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Credit &Memo';
                    Image = CreditMemo;
                    RunObject = Page "Sales Credit Memo";
                    RunPageMode = Create;
                    ToolTip = 'Create a new sales credit memo to revert a posted sales invoice.';
                }
                action("Sales &Fin. Charge Memo")
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales &Fin. Charge Memo';
                    Image = FinChargeMemo;
                    RunObject = Page "Finance Charge Memo";
                    RunPageMode = Create;
                    ToolTip = 'Create a new finance charge memo to fine a customer for late payment.';
                }
                action("Sales &Reminder")
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales &Reminder';
                    Image = Reminder;
                    RunObject = Page Reminder;
                    RunPageMode = Create;
                    ToolTip = 'Create a new reminder for a customer who has overdue payments.';
                }
            }
            group(Payables)
            {
                Caption = 'Payables';
                Image = Payables;
                action("&Vendor")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Vendor';
                    Image = Vendor;
                    RunObject = Page "Vendor Card";
                    RunPageMode = Create;
                    ToolTip = 'Set up a new vendor from whom you buy goods or services. ';
                }
                action("&Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Purchase Invoice';
                    Image = NewPurchaseInvoice;
                    RunObject = Page "Purchase Invoice";
                    RunPageMode = Create;
                    ToolTip = 'Create new purchase invoice.';
                }
                action("Advance Statement")
                {
                    Caption = 'Advance Statement';
                    Image = Document;
                    RunObject = Page "Purchase List";
                    RunPageView = where("Document Type" = const(Invoice),
                                        "Empl. Purchase" = const(true));
                    ToolTip = 'View information about payments made to and from responsible employees. This report also enables you to print and view primary documents of responsible employee expenses.';
                }
                action(Action1210057)
                {
                    Caption = 'Letter of Attorney List';
                    Image = List;
                    RunObject = Page "Letter of Attorney List";
                    ToolTip = 'View the list of documents that authorize individuals or organizations to act on the behalf of another to perform certain processes.';
                }
            }
        }
        area(processing)
        {
            group(Payments)
            {
                Caption = 'Payments';
                action("Cash Re&ceipt Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Re&ceipt Journal';
                    Image = CashReceiptJournal;
                    RunObject = Page "Cash Receipt Journal";
                    ToolTip = 'Open the cash receipt journal to post incoming payments.';
                }
                action("Payment &Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment &Journal';
                    Image = PaymentJournal;
                    RunObject = Page "Payment Journal";
                    ToolTip = 'View or edit the payment journal where you can register payments to vendors.';
                }
                action("Payment Registration")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Registration';
                    Image = Payment;
                    RunObject = Page "Payment Registration";
                    ToolTip = 'Apply customer payments observed on your bank account to non-posted sales documents to record that payment is made.';
                }
                action("B&ank Account Reconciliations")
                {
                    Caption = 'B&ank Account Reconciliations';
                    Image = BankAccountRec;
                    RunObject = Page "Bank Acc. Reconciliation";
                    Visible = false;
                }
                action("Payment Reconciliation Journals")
                {
                    Caption = 'Payment Reconciliation Journals';
                    Image = ApplyEntries;
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
                action("Import Currency Exch. Rate")
                {
                    Caption = 'Import Currency Exch. Rate';
                    Image = ImportChartOfAccounts;
                    RunObject = Report "Import Currency Exch. Rate";
                    ToolTip = 'Update currency exchange rates.';
                }
            }
            group(Action1210001)
            {
                Caption = 'VAT';
                action("VAT Settlement Worksteet")
                {
                    Caption = 'VAT Settlement Worksteet';
                    Image = Worksheet;
                    RunObject = Page "VAT Settlement Worksheet";
                    ToolTip = 'Plan which VAT amounts to settle. You must report the volume of your trade with European Union (EU) countries/regions to the tax authorities, even if no amount has to be settled.';
                }
                action("VAT Reinstatement Worksteet")
                {
                    Caption = 'VAT Reinstatement Worksteet';
                    Image = Worksheet;
                    RunObject = Page "VAT Reinstatement Worksheet";
                    ToolTip = 'Plan which VAT reinstatements to include in VAT ledgers.';
                }
                action("Calc. and Pos&t VAT Settlement")
                {
                    Caption = 'Calc. and Pos&t VAT Settlement';
                    Ellipsis = true;
                    Image = SettleOpenTransactions;
                    RunObject = Report "Calc. and Post VAT Settlement";
                    ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account. For every VAT posting group, the batch job finds all the VAT entries in the VAT Entry table that are included in the filters in the definition window.';
                    Visible = false;
                }
            }
            group(Action1210002)
            {
                Caption = 'Fixed Assets';
                action("Calculate Depreciation")
                {
                    Caption = 'Calculate Depreciation';
                    Image = CalculateDepreciation;
                    RunObject = Report "Calculate Depreciation";
                    ToolTip = 'Calculate depreciation according to conditions that you specify. If the related depreciation book is set up to integrate with the general ledger, then the calculated entries are transferred to the fixed asset general ledger journal. Otherwise, the calculated entries are transferred to the fixed asset journal. You can then review the entries and post the journal.';
                }
                action("Copy Depreciation")
                {
                    Caption = 'Copy Depreciation';
                    Image = CopyDepreciationBook;
                    RunObject = Report "Copy Depreciation Book";
                }
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                action("Post Inventor&y Cost to G/L")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Inventor&y Cost to G/L';
                    Ellipsis = true;
                    Image = PostInventoryToGL;
                    RunObject = Report "Post Inventory Cost to G/L";
                    ToolTip = 'Post the quantity and value changes to the inventory in the item ledger entries and the value entries when you post inventory transactions, such as sales shipments or purchase receipts.';
                }
            }
            group(Turnovers)
            {
                Caption = 'Turnovers';
                action("G/L Account Turnover")
                {
                    Caption = 'G/L Account Turnover';
                    Image = Turnover;
                    RunObject = Page "G/L Account Turnover";
                    ToolTip = 'View the general ledger account summary. You can use this information to verify if the entries are correct on general ledger accounts.';
                }
                action("Customer G/L Turnover")
                {
                    Caption = 'Customer G/L Turnover';
                    Image = Turnover;
                    RunObject = Page "Customer G/L Turnover";
                }
                action("Vendor G/L Turnover")
                {
                    Caption = 'Vendor G/L Turnover';
                    Image = Turnover;
                    RunObject = Page "Vendor G/L Turnover";
                    ToolTip = 'Analyze vendors'' turnover and account balances.';
                }
                action("Item G/L Turnover")
                {
                    Caption = 'Item G/L Turnover';
                    Image = Turnover;
                    RunObject = Page "Item G/L Turnover";
                    ToolTip = 'Prepare turnover sheets for goods and materials.';
                }
                action("FA G/L Turnover")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA G/L Turnover';
                    Image = Turnover;
                    RunObject = Page "FA G/L Turnover";
                    ToolTip = 'View the financial turnover as a result of fixed asset posting. General ledger entries are the basis for amounts shown in the window.';
                }
            }
            group(Action84)
            {
                Caption = 'Administration';
                action("Sa&les && Receivables Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sa&les && Receivables Setup';
                    Image = Setup;
                    RunObject = Page "Sales & Receivables Setup";
                    ToolTip = 'Define your general policies for sales invoicing and returns, such as when to show credit and stockout warnings and how to post sales discounts. Set up your number series for creating customers and different sales documents.';
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
