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
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Task;
using Microsoft.Inventory.Costing;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Reports;
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
                action("Trial Balance - Debit/Credit")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trial Balance - Debit/Credit';
                    Image = "Report";
                    RunObject = Report "Trial Balance - Debit/Credit";
                    ToolTip = 'View all accounts in the chart of accounts with their balances and net changes. The list includes starting balance, debit and credit net changes during the specified period, and the final balance of the accounts. For example, you can choose to view a trial balance for selected departments or projects.';
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
            separator(Action1010001)
            {
            }
            action("Sales Ledger")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Ledger';
                Image = "Report";
                RunObject = Report "Sales Ledger";
                ToolTip = 'View the general ledger entries that have been posted in a sales journal template. This report is useful to document a register''s contents for internal or external audits. The first part provides a detailed overview of the general ledger entries, sorted according to date and per document. The second part displays totals for every general ledger account, and also the total debit and the total credit amount. The third part contains total amounts for each VAT row.';
            }
            action("Purchase Ledger")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Ledger';
                Image = "Report";
                RunObject = Report "Purchase Ledger";
                ToolTip = 'View the general ledger entries that have been posted in a purchase journal template. This report is useful to document a register''s contents for internal or external audits. The first part provides a detailed overview of the general ledger entries, sorted according to date and per document. The second part displays totals for every general ledger account, and also the total debit and the total credit amount. The third part contains total amounts for each VAT row.';
            }
            action("General Ledger")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'General Ledger';
                Image = GLRegisters;
                RunObject = Report "General Ledger";
                ToolTip = 'View the general ledger entries that have been posted in a journal template. This report is useful to document a register''s contents for internal or external audits. The first part provides a detailed overview of the general ledger entries, sorted according to date and per document. The second part displays totals for every general ledger account, and also the total debit and the total credit amount. The third part contains total amounts for each VAT row.';
            }
            action("Centralization Ledger")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Centralization Ledger';
                Image = "Report";
                RunObject = Report "Centralization Ledger";
                ToolTip = 'Shows the total amounts of the general ledger entries that have been posted. This report is useful to document a register''s contents for internal or external audits. By default, the report provides an overview of the amounts posted for each journal template name. The list shows debit and credit amounts (both in LCY). In addition, the total debit and credit amounts for all journal templates are shown.';
            }
            action("Financial Ledger")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Financial Ledger';
                Image = "Report";
                RunObject = Report "Financial Ledger";
                ToolTip = 'View the general ledger entries that have been posted in a journal template. This report is useful to document a register''s contents for internal or external audits. The first part provides a detailed overview of the general ledger entries, sorted according to date and per document. The second part displays totals for every general ledger account, and also the total debit and the total credit amount. The third part contains total amounts for each VAT row.';
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
                ApplicationArea = Basic, Suite;
                Caption = 'G/L - VAT Reconciliation';
                Image = "Report";
                RunObject = Report "G/L - VAT Reconciliation";
                ToolTip = 'Verify that the VAT amounts on the VAT statements match the amounts from the G/L entries.';
            }
            action("VAT - Form")
            {
                ApplicationArea = VAT;
                Caption = 'VAT - Form';
                Image = "Report";
                RunObject = Report "VAT - Form";
                ToolTip = 'Send monthly or quarterly VAT declarations to an XML file. You can choose to print your VAT declaration and send the printed document to your tax authorities or you can send an electronic VAT declaration via the internet using Intervat. Note: This report is based on the VAT Statement template that is defined in the general ledger setup. Therefore, it may export data that is not the same as what is shown in the VAT Statement Preview window.';
            }
            action("Checklist Revenue and VAT")
            {
                ApplicationArea = VAT;
                Caption = 'Checklist Revenue and VAT';
                Image = "Report";
                RunObject = Report "Checklist Revenue and VAT";
                ToolTip = 'Compare the base amounts of revenue that are printed in the VAT declarations to the data in your accounting system. This is a default check that is performed during a general audit of your bookkeeping.';
            }
            action("VAT Statement Lines")
            {
                ApplicationArea = VAT;
                Caption = 'VAT Statement Lines';
                Image = "Report";
                RunObject = Report "VAT Statement Lines";
                ToolTip = 'View all lines in the selected VAT declarations. This report is useful for verification.';
            }
            action("VAT Statement Summary")
            {
                ApplicationArea = VAT;
                Caption = 'VAT Statement Summary';
                Image = "Report";
                RunObject = Report "VAT Statement Summary";
                ToolTip = 'View a summary of the VAT declarations for different accounting periods. You can also use the report to verify the amounts in the different VAT rows. For example, you can check if the sum of two rows equals the amount in another row.';
            }
            action("VAT - VIES Declaration Dis&k")
            {
                ApplicationArea = BasicEU;
                Caption = 'VAT - VIES Declaration Dis&k';
                Image = "Report";
                RunObject = Report "VAT-VIES Declaration Disk BE";
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
            action("VAT Annual Listing")
            {
                ApplicationArea = VAT;
                Caption = 'VAT Annual Listing';
                Image = "Report";
                RunObject = Report "VAT Annual Listing";
                ToolTip = 'View or print yearly VAT declarations on paper. The layout and the usage of this document have been officially approved by the Ministry of Finance. You can send the printed document to your tax authorities.';
            }
            action("VAT Annual Listing - Disk")
            {
                ApplicationArea = VAT;
                Caption = 'VAT Annual Listing - Disk';
                Image = "Report";
                RunObject = Report "VAT Annual Listing - Disk";
                ToolTip = 'Send the yearly VAT declarations to a disk or an XML file. The XML file can be used to declare the Annual listing (form 725) in XML on the Intervat website. The Belgian government recommends that you use this method of declaration.';
            }
            action("Link to Accon")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Link to Accon';
                Image = "Report";
                RunObject = Report "Link to Accon";
                ToolTip = 'Create a file that can be imported into the ACCON program to create an annual income statement. The report exports the total balances of the general ledger accounts for a specific period to a file on disk.';
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
                RunObject = Page "EB Payment Journal Batches";
                ToolTip = 'Open the list of payment journals where you can register payments to vendors.';
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
                RunObject = Page "EB Payment Journal";
                ToolTip = 'View or edit the payment journal where you can register payments to vendors.';
            }
            action("Payment Registration")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Registration';
                Image = Payment;
                RunObject = Page "Payment Registration";
                ToolTip = 'Apply customer payments observed on your bank account to non-posted sales documents to record that payment is made.';
                Visible = false;
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
            action("Electronic Banking Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Electronic Banking Setup';
                Image = ReceivablesPayablesSetup;
                RunObject = Page "Electronic Banking Setup";
                ToolTip = 'View a statement of posted VAT and calculates the duty liable to the customs authorities for the selected period. The report is printed on the basis of the definition of the VAT statement in the VAT Statement Line table. The report can be used in connection with VAT settlement to the customs authorities and for your own documentation.';
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
