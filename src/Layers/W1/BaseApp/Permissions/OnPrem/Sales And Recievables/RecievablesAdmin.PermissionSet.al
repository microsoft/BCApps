namespace System.Security.AccessControl;

using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Setup;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Document;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Reporting;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Shipping;

permissionset 3723 "Recievables - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'S&R  setup';

    Permissions = tabledata "Additional Fee Setup" = RIMD,
                  tabledata "Alt. Customer Posting Group" = RIMD,
                  tabledata "Base Calendar" = RIMD,
                  tabledata "Base Calendar Change" = RIMD,
                  tabledata "Currency for Fin. Charge Terms" = RIMD,
                  tabledata "Currency for Reminder Level" = RIMD,
                  tabledata "Cust. Invoice Disc." = RIMD,
                  tabledata "Customer Posting Group" = RIMD,
                  tabledata "Customized Calendar Change" = RIMD,
                  tabledata "Customized Calendar Entry" = RIMD,
                  tabledata "Dispute Status" = RIMD,
                  tabledata "Finance Charge Terms" = RIMD,
                  tabledata "Finance Charge Text" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Jnl. Allocation" = MD,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Journal Line" = MD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "Item Charge" = RIMD,
                  tabledata "Line Fee Note on Report Hist." = RIMD,
                  tabledata "Payment Method" = RIMD,
                  tabledata "Payment Terms" = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Reminder Attachment Text" = RIMD,
                  tabledata "Reminder Attachment Text Line" = RIMD,
                  tabledata "Reminder Email Text" = RIMD,
                  tabledata "Reminder Level" = RIMD,
                  tabledata "Reminder Terms" = RIMD,
                  tabledata "Reminder Action Group" = RIMD,
                  tabledata "Reminder Action" = RIMD,
                  tabledata "Create Reminders Setup" = RIMD,
                  tabledata "Issue Reminders Setup" = RIMD,
                  tabledata "Send Reminders Setup" = RIMD,
                  tabledata "Reminder Automation Error" = RIMD,
                  tabledata "Reminder Action Group Log" = RIMD,
                  tabledata "Reminder Action Log" = RIMD,
                  tabledata "Reminder Terms Translation" = RIMD,
                  tabledata "Reminder Text" = RIMD,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Return Reason" = RIMD,
                  tabledata "Sales & Receivables Setup" = RIMD,
                  tabledata "Sales Discount Access" = RIMD,
                  tabledata "Sales Line Discount" = RIMD,
                  tabledata "Salesperson/Purchaser" = RIMD,
                  tabledata "Shipment Method" = RIMD,
                  tabledata "Shipping Agent" = RIMD,
                  tabledata "Shipping Agent Services" = RIMD,
                  tabledata "Sorting Table" = RIMD,
                  tabledata "Source Code Setup" = R,
                  tabledata "Standard Customer Sales Code" = RIMD,
                  tabledata "Standard Sales Code" = RIMD,
                  tabledata "Standard Sales Line" = RIMD;
}
