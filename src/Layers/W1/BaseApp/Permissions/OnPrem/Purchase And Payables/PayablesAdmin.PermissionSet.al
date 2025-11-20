namespace System.Security.AccessControl;

using Microsoft.Sales.FinanceCharge;
using Microsoft.HumanResources.Employee;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Setup;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Finance.SalesTax;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Reporting;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Shipping;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;

permissionset 6092 "Payables - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'P&P setup';

    Permissions = tabledata "Base Calendar" = RIMD,
                  tabledata "Base Calendar Change" = RIMD,
                  tabledata "Currency for Fin. Charge Terms" = RIMD,
                  tabledata "Customized Calendar Change" = RIMD,
                  tabledata "Customized Calendar Entry" = RIMD,
                  tabledata "Employee Posting Group" = RIMD,
                  tabledata "Finance Charge Terms" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Jnl. Allocation" = D,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Journal Line" = MD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "Item Charge" = RIMD,
                  tabledata "Payment Method" = RIMD,
                  tabledata "Payment Terms" = RIMD,
                  tabledata "Purchases & Payables Setup" = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Req. Wksh. Template" = RIMD,
                  tabledata "Requisition Line" = D,
                  tabledata "Requisition Wksh. Name" = RIMD,
                  tabledata "Return Reason" = RIMD,
                  tabledata "Salesperson/Purchaser" = RIMD,
                  tabledata "Shipment Method" = RIMD,
                  tabledata "Source Code Setup" = R,
                  tabledata "Standard Purchase Code" = RIMD,
                  tabledata "Standard Purchase Line" = RIMD,
                  tabledata "Standard Vendor Purchase Code" = RIMD,
                  tabledata "Tax Area" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "Vendor Invoice Disc." = RIMD,
                  tabledata "Vendor Posting Group" = RIMD;
}
