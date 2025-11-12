namespace System.Security.AccessControl;

using Microsoft.Finance.FinancialReports;
using Microsoft.Integration.Entity;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Analysis;
using Microsoft.Finance.Analysis;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Bank.Check;
using Microsoft.Foundation.Company;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Customer;
using Microsoft.Finance.Dimension;
using Microsoft.HumanResources.Payables;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Ledger;
using System.Environment.Configuration;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Finance.SalesTax;
using Microsoft.Purchases.Payables;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;

permissionset 7576 "D365 FINANCIAL REP."
{
    Assignable = true;

    Caption = 'Dynamics 365 Financial reports';
    Permissions = tabledata "Acc. Sched. KPI Web Srv. Line" = RIMD,
                  tabledata "Acc. Sched. KPI Web Srv. Setup" = RIMD,
                  tabledata "Acc. Schedule Line" = RIMD,
                  tabledata "Acc. Schedule Line Entity" = RIMD,
                  tabledata "Acc. Schedule Name" = RIMD,
                  tabledata "Alloc. Acc. Manual Override" = RIMD,
                  tabledata "Alloc. Account Distribution" = RIMD,
                  tabledata "Allocation Account" = RIMD,
                  tabledata "Allocation Line" = RIMD,
                  tabledata "Financial Report" = RIMD,
                  tabledata "Financial Report Export Log" = RIMD,
                  tabledata "Financial Report Recipient" = RIMD,
                  tabledata "Financial Report Schedule" = RIMD,
                  tabledata "Financial Report User Filters" = RIMD,
                  tabledata "Fin. Report Excel Template" = RIMD,
                  tabledata "Accounting Period" = RIMD,
                  tabledata "Analysis Column" = RIMD,
                  tabledata "Analysis Column Template" = RIMD,
                  tabledata "Analysis Field Value" = Rimd,
                  tabledata "Analysis Line" = RIMD,
                  tabledata "Analysis Line Template" = RIMD,
                  tabledata "Analysis Report Name" = RIMD,
                  tabledata "Analysis Type" = RIMD,
                  tabledata "Analysis View" = RIMD,
                  tabledata "Analysis View Budget Entry" = RIMD,
                  tabledata "Analysis View Entry" = RIMD,
                  tabledata "Bank Acc. Reconciliation" = RIMD,
                  tabledata "Bank Acc. Reconciliation Line" = RIMD,
                  tabledata "Bank Acc. Rec. Match Buffer" = RIMD,
                  tabledata "Bank Account" = RM,
                  tabledata "Bank Account Ledger Entry" = Rimd,
                  tabledata "Bank Account Posting Group" = RIMD,
                  tabledata "Bank Account Statement" = RimD,
                  tabledata "Bank Account Statement Line" = Rimd,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata "Check Ledger Entry" = Rimd,
                  tabledata "Company Information" = RM,
                  tabledata "Contact Business Relation" = R,
                  tabledata Currency = RIMD,
                  tabledata "Currency Exchange Rate" = RIMD,
                  tabledata "Cust. Ledger Entry" = Rimd,
                  tabledata Customer = Rimd,
                  tabledata "Date Compr. Register" = Rimd,
                  tabledata Dimension = RIMD,
                  tabledata "Employee Ledger Entry" = Rimd,
                  tabledata "Exch. Rate Adjmt. Reg." = Rimd,
                  tabledata "G/L Account (Analysis View)" = RIMD,
                  tabledata "G/L Account" = RIMD,
                  tabledata "G/L Account Category" = RIMD,
                  tabledata "G/L Budget Entry" = RIMD,
                  tabledata "G/L Budget Name" = RIMD,
                  tabledata "G/L Entry - VAT Entry Link" = R,
                  tabledata "G/L Entry" = Rimd,
                  tabledata "G/L Register" = Rimd,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "General Ledger Setup" = RM,
                  tabledata "Item Analysis View" = RIMD,
                  tabledata "Item Analysis View Budg. Entry" = Rimd,
                  tabledata "Item Analysis View Entry" = Rimd,
                  tabledata "Item Analysis View Filter" = RIMD,
                  tabledata "Item Budget Entry" = RIMD,
                  tabledata "Item Budget Name" = RIMD,
                  tabledata "Item Ledger Entry" = Rimd,
                  tabledata "Object Options" = RIMD,
                  tabledata "Payment Rec. Related Entry" = RIMD,
                  tabledata "Pmt. Rec. Applied-to Entry" = RIMD,
                  tabledata "Purchase Header" = Rmd,
                  tabledata "Purchase Line" = Rmd,
                  tabledata "Sales Header" = Rmd,
                  tabledata "Sales Line" = Rmd,
                  tabledata "Tariff Number" = R,
                  tabledata "Tax Area" = RIMD,
                  tabledata "Tax Area Line" = RIMD,
                  tabledata "Tax Area Translation" = RIMD,
                  tabledata "Tax Detail" = RIMD,
                  tabledata "Tax Group" = RIMD,
                  tabledata "Tax Jurisdiction" = RIMD,
                  tabledata "Tax Jurisdiction Translation" = RIMD,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "VAT Amount Line" = RIMD,
                  tabledata "VAT Entry" = Rimd,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Report Error Log" = RIMD,
                  tabledata "VAT Report Header" = RIMD,
                  tabledata "VAT Report Line" = RIMD,
                  tabledata "VAT Report Line Relation" = RIMD,
                  tabledata "VAT Report Setup" = RIMD,
                  tabledata "VAT Return Period" = RIMD,
                  tabledata "VAT Statement Line" = RIMD,
                  tabledata "VAT Statement Name" = RIMD,
                  tabledata "VAT Statement Template" = RIMD,
                  tabledata "VAT Setup" = RM,
                  tabledata "Vendor Ledger Entry" = Rimd;
}
