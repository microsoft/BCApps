namespace System.Security.AccessControl;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.HumanResources.Payables;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Warehouse.Ledger;
using System.Environment.Configuration;

permissionset 681 "D365 JOURNALS, POST"
{
    Assignable = true;
    Caption = 'Dynamics 365 Post journals';

    IncludedPermissionSets = "D365 JOURNALS, EDIT";

    Permissions = tabledata "Avg. Cost Adjmt. Entry Point" = RIM,
                  tabledata "Bank Account Ledger Entry" = Rim,
                  tabledata "Bank Account Posting Group" = R,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata Currency = RIMD,
                  tabledata "Currency Exchange Rate" = RIM,
                  tabledata "Cust. Invoice Disc." = R,
                  tabledata "Cust. Ledger Entry" = imd,
                  tabledata "Detailed Cust. Ledg. Entry" = imd,
                  tabledata "Detailed Employee Ledger Entry" = imd,
                  tabledata "Detailed Vendor Ledg. Entry" = imd,
                  tabledata "Employee Ledger Entry" = imd,
                  tabledata "G/L Account" = RIMD,
                  tabledata "G/L Account Source Currency" = RIMD,
                  tabledata "G/L - Item Ledger Relation" = RIMD,
                  tabledata "G/L Entry - VAT Entry Link" = Ri,
                  tabledata "G/L Entry" = Rimd,
                  tabledata "Item Register" = Rimd,
                  tabledata "Job Ledger Entry" = Rimd,
                  tabledata "Notification Entry" = RIMD,
                  tabledata "Sent Notification Entry" = RIMD,
                  tabledata "VAT Entry" = Rimd,
                  tabledata "VAT Return Period" = R,
                  tabledata "Vendor Ledger Entry" = imd,
                  tabledata "Warehouse Register" = r;
}
