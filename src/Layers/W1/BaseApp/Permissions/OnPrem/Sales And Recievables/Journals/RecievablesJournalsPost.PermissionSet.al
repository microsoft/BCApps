namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Finance.Analysis;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Check;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.SalesTax;
using System.Security.User;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Calculation;

permissionset 6207 "Recievables Journals - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post journals (S&R)';

    Permissions = tabledata "Accounting Period" = r,
                  tabledata "Additional Fee Setup" = r,
                  tabledata "Alt. Customer Posting Group" = r,
                  tabledata "Analysis View" = rimd,
                  tabledata "Analysis View Entry" = rim,
                  tabledata "Analysis View Filter" = r,
                  tabledata "Bank Account" = m,
                  tabledata "Bank Account Ledger Entry" = rim,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata "Check Ledger Entry" = rim,
                  tabledata Currency = r,
                  tabledata "Currency Exchange Rate" = r,
                  tabledata "Currency for Reminder Level" = r,
                  tabledata "Cust. Ledger Entry" = rim,
                  tabledata Customer = r,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Date Compr. Register" = r,
                  tabledata "Detailed Cust. Ledg. Entry" = ri,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "G/L Account" = r,
                  tabledata "G/L Account Source Currency" = Ri,
                  tabledata "G/L Entry - VAT Entry Link" = Ri,
                  tabledata "G/L Entry" = Ri,
                  tabledata "G/L Register" = Rim,
                  tabledata "Gen. Jnl. Allocation" = RIMD,
                  tabledata "Gen. Journal Batch" = RID,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "Gen. Journal Template" = RI,
                  tabledata "General Ledger Setup" = r,
                  tabledata "General Posting Setup" = r,
                  tabledata "Line Fee Note on Report Hist." = rim,
                  tabledata "Reminder Level" = r,
                  tabledata "Reminder Terms" = r,
                  tabledata "Reminder Terms Translation" = r,
                  tabledata "Reversal Entry" = RIMD,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "User Setup" = r,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Entry" = Ri,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Alt. Cust. VAT Reg." = R;
}
