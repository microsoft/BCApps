namespace System.Security.AccessControl;

using Microsoft.Sales.Customer;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Calculation;

permissionset 7071 "Recievables - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'S&R  periodic activities';

    Permissions = tabledata "Additional Fee Setup" = R,
                  tabledata "Alt. Customer Posting Group" = r,
                  tabledata "Country/Region" = R,
                  tabledata Currency = rm,
                  tabledata "Currency for Fin. Charge Terms" = R,
                  tabledata "Currency for Reminder Level" = R,
                  tabledata "Cust. Ledger Entry" = Rimd,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Customer Posting Group" = r,
                  tabledata "Date Compr. Register" = RimD,
                  tabledata "Detailed Cust. Ledg. Entry" = Rimd,
                  tabledata "Dispute Status" = RIMD,
                  tabledata "Fin. Charge Comment Line" = RIMD,
                  tabledata "Finance Charge Memo Header" = RIMD,
                  tabledata "Finance Charge Memo Line" = RIMD,
                  tabledata "Finance Charge Terms" = R,
                  tabledata "Finance Charge Text" = R,
                  tabledata "G/L Register" = Rimd,
                  tabledata "Gen. Journal Batch" = R,
                  tabledata "Gen. Journal Line" = RImd,
                  tabledata "Gen. Journal Template" = R,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "General Posting Setup" = r,
                  tabledata "Issued Fin. Charge Memo Header" = Rimd,
                  tabledata "Issued Fin. Charge Memo Line" = Rimd,
                  tabledata "Issued Reminder Header" = Rimd,
                  tabledata "Issued Reminder Line" = Rimd,
                  tabledata Item = R,
                  tabledata "Item Charge Assignment (Sales)" = RI,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Variant" = R,
                  tabledata "Job Ledger Entry" = R,
                  tabledata "Line Fee Note on Report Hist." = R,
                  tabledata "Reminder Comment Line" = RIMD,
                  tabledata "Reminder Attachment Text" = R,
                  tabledata "Reminder Attachment Text Line" = R,
                  tabledata "Reminder Header" = RIMD,
                  tabledata "Reminder Email Text" = R,
                  tabledata "Reminder Level" = R,
                  tabledata "Reminder Line" = RIMD,
                  tabledata "Reminder Terms" = R,
                  tabledata "Reminder Terms Translation" = R,
                  tabledata "Reminder Text" = R,
                  tabledata "Reminder Action Group" = R,
                  tabledata "Reminder Action" = R,
                  tabledata "Create Reminders Setup" = R,
                  tabledata "Issue Reminders Setup" = R,
                  tabledata "Send Reminders Setup" = R,
                  tabledata "Reminder Automation Error" = R,
                  tabledata "Reminder Action Group Log" = R,
                  tabledata "Reminder Action Log" = R,
                  tabledata "Reminder/Fin. Charge Entry" = Rimd,
                  tabledata "Return Receipt Header" = R,
                  tabledata "Return Receipt Line" = R,
                  tabledata "Sales Header" = R,
                  tabledata "Sales Line" = RI,
                  tabledata "Sales Shipment Header" = R,
                  tabledata "Sales Shipment Line" = R,
                  tabledata "Sorting Table" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "Value Entry" = R,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Alt. Cust. VAT Reg." = R;
}
