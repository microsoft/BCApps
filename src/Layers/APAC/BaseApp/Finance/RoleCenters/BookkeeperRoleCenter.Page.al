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
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Task;
using Microsoft.Inventory.Costing;
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
            group("Financial Statements")
            {
                Caption = 'Financial Statements';
                action("Balance Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance Sheet';
                    Image = "Report";
                    RunObject = Report "Balance Sheet";
                    ToolTip = 'Print the legal report that is required in Australia for accounts auditing. You can choose to round the amounts in display by tens, hundreds, thousands, hundred thousands or millions factor.';
                }
                action("Income Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Income Statement';
                    Image = "Report";
                    RunObject = Report "Income Statement";
                    ToolTip = 'View the income statement.';
                }
                action("Financial Analysis Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Financial Analysis Report';
                    Image = "Report";
                    RunObject = Report "Financial Analysis Report";
                    ToolTip = 'Open a report that compares the Balance at Date, Balance, Net Change, and Budget from the G/L account with budget entries or previous year entries according to your selection.';
                }
                action("Transaction Detail")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Detail';
                    Image = "Report";
                    RunObject = Report "Transaction Detail Report";
                    ToolTip = 'View the information detail.';
                }
            }
            separator(Action49)
            {
            }
#if not CLEAN28
            action("&Aged Accounts Receivable")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Aged Accounts Receivable (Obsolete)';
                Image = "Report";
                RunObject = Report "Aged Accounts Receivable";
                ToolTip = 'View overdue customer payments.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Aged Accounts Receivable (Excel). This report will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
            action("Aged Accou&nts Payable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Aged Accou&nts Payable (Obsolete)';
                Image = "Report";
                RunObject = Report "Aged Accounts Payable";
                ToolTip = 'View an overview of when your payables to vendors are due or overdue (divided into four periods). You must specify the date you want aging calculated from and the length of the period that each column will contain data for.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Aged Accounts Payable (Excel). This report will be removed in a future release.';
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
            action("Aged Acc. Rec. (BackDating)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Aged Acc. Rec. (BackDating)';
                Image = "Report";
                RunObject = Report "Aged Acc. Rec. (BackDating)";
                ToolTip = 'View outstanding balance information based on the selections you make in the report request window.';
            }
            action("Aged Acc. Pay. (BackDating)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Aged Acc. Pay. (BackDating)';
                Image = "Report";
                RunObject = Report "Aged Acc. Pay. (BackDating)";
                ToolTip = 'View outstanding balance information based on the selections you make in the report request window.';
            }
            action("AU/NZ Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'AU/NZ Statement';
                Image = "Report";
                RunObject = Report "AU/NZ Statement";
                ToolTip = 'Print the report of accounts receivable and accounts payable based on the selections you make in the report request window.';
            }
            separator(Action53)
            {
            }
            action("VAT Reg&istration No. Check")
            {
                ApplicationArea = VAT;
                Caption = 'VAT Reg&istration No. Check';
                Image = "Report";
                RunObject = Report "VAT Registration No. Check";
                ToolTip = 'Use an EU VAT number validation service to validated the VAT number of a business partner.';
            }
            action("VAT E&xceptions")
            {
                ApplicationArea = VAT;
                Caption = 'VAT E&xceptions';
                Image = "Report";
                RunObject = Report "VAT Exceptions";
                ToolTip = 'View the VAT entries that were posted and placed in a general ledger register in connection with a VAT difference. The report is used to document adjustments made to VAT amounts that were calculated for use in internal or external auditing.';
            }
            action("VAT State&ment")
            {
                ApplicationArea = VAT;
                Caption = 'VAT State&ment';
                Image = "Report";
                RunObject = Report "VAT Statement";
                ToolTip = 'View a statement of posted VAT and calculate the duty liable to the customs authorities for the selected period.';
            }
            action("G/L - VAT Reconciliation")
            {
                ApplicationArea = VAT;
                Caption = 'G/L - VAT Reconciliation';
                Image = "Report";
                RunObject = Report "G/L - VAT Reconciliation";
                ToolTip = 'Verify that the VAT amounts on the VAT statements match the amounts from the G/L entries.';
            }
            action("VAT Report - Vendor")
            {
                ApplicationArea = VAT;
                Caption = 'VAT Report - Vendor';
                Image = "Report";
                RunObject = Report "VAT Report - Vendor";
                ToolTip = 'Run a report of VAT entries for vendors. The report is based on the filters that you set up in the request window.';
            }
            action("VAT Report - Customer")
            {
                ApplicationArea = VAT;
                Caption = 'VAT Report - Customer';
                Image = "Report";
                RunObject = Report "VAT Report - Customer";
                ToolTip = 'Run a report of VAT entries for customers. The report is based on the filters that you set up in the request window.';
            }
            action("Quarterly VAT Return")
            {
                ApplicationArea = VAT;
                Caption = 'Quarterly VAT Return';
                Image = "Report";
                RunObject = Report "Quarterly VAT Return";
                ToolTip = 'Create a new VAT return.';
            }
            action("Monthly VAT Declaration")
            {
                ApplicationArea = VAT;
                Caption = 'Monthly VAT Declaration';
                Image = "Report";
                RunObject = Report "Monthly VAT Declaration";
                ToolTip = 'Start the process of creating the monthly VAT declaration.';
            }
            action("VAT - VI&ES Declaration Tax Auth")
            {
                ApplicationArea = BasicEU;
                Caption = 'VAT - VI&ES Declaration Tax Auth';
                Image = "Report";
                RunObject = Report "VAT- VIES Declaration Tax Auth";
                ToolTip = 'View information to the customs and tax authorities for sales to other EU countries/regions. If the information must be printed to a file, you can use the VAT- VIES Declaration Disk report.';
            }
            action("VAT - VIES Declaration Dis&k")
            {
                ApplicationArea = BasicEU;
                Caption = 'VAT - VIES Declaration Dis&k';
                Image = "Report";
                RunObject = Report "VAT- VIES Declaration Disk";
                ToolTip = 'Report your sales to other EU countries or regions to the customs and tax authorities. If the information must be printed out on a printer, you can use the VAT- VIES Declaration Tax Auth report. The information is shown in the same format as in the declaration list from the customs and tax authorities.';
            }
            action("EC &Sales List")
            {
                ApplicationArea = BasicEU;
                Caption = 'EC &Sales List';
                Image = "Report";
                RunObject = Report "EC Sales List";
                ToolTip = 'Calculate VAT amounts from sales, and submit the amounts to a tax authority.';
            }
            separator(Action1500019)
            {
            }
            action("WHT PND 1")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 1';
                Image = "Report";
                RunObject = Report "WHT PND 1";
                ToolTip = 'Open the WHT PND 1 report.';
            }
            action("WHT PND 2")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 2';
                Image = "Report";
                RunObject = Report "WHT PND 2";
                ToolTip = 'Open the WHT PND 2 report.';
            }
            action("WHT PND 3")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 3';
                Image = "Report";
                RunObject = Report "WHT PND 3";
                ToolTip = 'Open the WHT PND 3 report.';
            }
            action("WHT PND 53")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 53';
                Image = "Report";
                RunObject = Report "WHT Report - PND 53";
                ToolTip = 'Open the WHT PND 53 report.';
            }
            action("Certificate of Creditable tax")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Certificate of Creditable tax';
                Image = "Report";
                RunObject = Report "Certificate of Creditable tax";
                ToolTip = 'Start the process of submitting the certificate of creditable tax.';
            }
            action("Monthly Remittance Return WHT")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Monthly Remittance Return WHT';
                Image = "Report";
                RunObject = Report "Monthly Remittance Return  WHT";
                ToolTip = 'Start the process of creating the monthly remittance return for withholding tax.';
            }
            action("E-Filing")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Filing';
                Image = "Report";
                RunObject = Report "E-Filing";
                ToolTip = 'Start the electronic submission of withholding tax report.';
            }
            separator(Action1500024)
            {
            }
            action("Bank Account Reconcilation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Reconcilation';
                Image = "Report";
                RunObject = Report "Bank Account Reconciliation";
                ToolTip = 'Prepare to print a report of bank ledger entries that are not recorded so that it helps in bank reconciliation. This report reconciles the balance of a defined bank account as at a defined date. The report displays open bank ledger entries as either unpresented checks or deposits not recorded.';
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
        }
        area(sections)
        {
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
                action("Posted Sales Tax Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Tax Invoices';
                    RunObject = Page "Posted Sales Tax Invoices";
                    ToolTip = 'View the list of posted documents.';
                }
                action("Posted Sales Tax Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Tax Credit Memos';
                    RunObject = Page "Posted Sales Tax Cr. Memos";
                    ToolTip = 'View the list of posted documents.';
                }
                action("Posted Purch. Tax Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Purch. Tax Invoices';
                    RunObject = Page "Posted Purch. Tax Invoices";
                    ToolTip = 'View the list of posted documents.';
                }
                action("Posted Purch. Tax Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Purch. Tax Credit Memos';
                    RunObject = Page "Posted Purch. Tax Cr. Memos";
                    ToolTip = 'View the list of posted documents.';
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
            }
        }
        area(creation)
        {
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
            separator(Action554)
            {
            }
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
        }
        area(processing)
        {
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
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
            separator(Action77)
            {
            }
            action("Payment Reconciliation Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Reconciliation Journals';
                Image = ApplyEntries;
                RunObject = Page "Pmt. Reconciliation Journals";
                RunPageMode = View;
                ToolTip = 'Reconcile unpaid documents automatically with their related bank transactions by importing a bank statement feed or file. In the payment reconciliation journal, incoming or outgoing payments on your bank are automatically, or semi-automatically, applied to their related open customer or vendor ledger entries. Any open bank account ledger entries related to the applied customer or vendor ledger entries will be closed when you choose the Post Payments and Reconcile Bank Account action. This means that the bank account is automatically reconciled for payments that you post with the journal.';
            }
            action("B&ank Account Reconciliations")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'B&ank Account Reconciliations';
                Image = BankAccountRec;
                RunObject = Page "Bank Acc. Reconciliation";
                ToolTip = 'Reconcile entries in your bank account ledger entries with the actual transactions in your bank account, according to the latest bank statement.';
            }
            action("Adjust E&xchange Rates")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adjust E&xchange Rates';
                Ellipsis = true;
                Image = AdjustExchangeRates;
                RunObject = Codeunit "Exch. Rate Adjmt. Run Handler";
                ToolTip = 'Adjust general ledger, customer, vendor, and bank account entries to reflect a more updated balance if the exchange rate has changed since the entries were posted.';
            }
            action("Post Inventor&y Cost to G/L")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Post Inventor&y Cost to G/L';
                Ellipsis = true;
                Image = PostInventoryToGL;
                RunObject = Report "Post Inventory Cost to G/L";
                ToolTip = 'Post the quantity and value changes to the inventory in the item ledger entries and the value entries when you post inventory transactions, such as sales shipments or purchase receipts.';
            }
            action("Calc. and Pos&t VAT Settlement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calc. and Pos&t VAT Settlement';
                Ellipsis = true;
                Image = SettleOpenTransactions;
                RunObject = Report "Calc. and Post VAT Settlement";
                ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account. For every VAT posting group, the batch job finds all the VAT entries in the VAT Entry table that are included in the filters in the definition window.';
            }
            action("Calc. and Post WHT Settlement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calc. and Post WHT Settlement';
                Image = "Report";
                RunObject = Report "Calc. and Post WHT Settlement";
                ToolTip = 'Start the process of calculating and posting the withholding tax settlement.';
            }
            action("Adjust Settlement Exch. Rates")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adjust Settlement Exch. Rates';
                Image = "Report";
                RunObject = Report "Adjust Settlement Exch. Rates";
                ToolTip = 'Settle the VAT entries to the government exchange rate based on the dates that you specify. You can also specify if you want to use a daily settlement exchange rate.';
            }
            action("Calculate GST Settlement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calculate GST Settlement';
                Image = CalculateSalesTax;
                RunObject = Report "Calculate GST Settlement";
                ToolTip = 'Start the process of calculating the GST settlement.';
            }
            group(BAS)
            {
                Caption = 'BAS';
                action("BAS-Update")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BAS-Update';
                    Image = "Report";
                    RunObject = Report "BAS-Update";
                    ToolTip = 'Start the process of submiting a new Business Activity Statement (BAS).';
                }
                action("Print BAS Export File")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print BAS Export File';
                    Image = "Report";
                    RunObject = Report "Print BAS Export File";
                    ToolTip = 'Start the process of printing the business activity statement (BAS) export file.';
                }
                action("BAS Calculation Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BAS Calculation Sheet';
                    Image = CalculateVAT;
                    RunObject = Page "BAS Calculation Sheet";
                    ToolTip = 'View or edit the business activity statement (BAS) calculation information for goods and services tax (GST).';
                }
                action("BAS Setup Preview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BAS Setup Preview';
                    Image = View;
                    RunObject = Page "BAS Setup Preview";
                    ToolTip = 'See a preview of the BAS. Optionally, export the preview to Excel for manual adjustments.';
                }
            }
            separator(Action84)
            {
                Caption = 'Administration';
                IsHeader = true;
            }
            action("Sa&les && Receivables Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sa&les && Receivables Setup';
                Image = Setup;
                RunObject = Page "Sales & Receivables Setup";
                ToolTip = 'Define your general policies for sales invoicing and returns, such as when to show credit and stockout warnings and how to post sales discounts. Set up your number series for creating customers and different sales documents.';
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
