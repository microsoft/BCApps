namespace System.Security.AccessControl;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Consolidation;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Finance.Dimension;
using Microsoft.HumanResources.Employee;
using Microsoft.Foundation.ExtendedText;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Calculation;

permissionset 4123 "General Ledger Accounts - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read G/L accounts and entries';

    Permissions = tabledata "Bank Account Posting Group" = R,
                  tabledata "Business Unit" = R,
                  tabledata "Business Unit Information" = R,
                  tabledata "Business Unit Setup" = R,
                  tabledata "Comment Line" = R,
                  tabledata "Consolidation Account" = R,
                  tabledata Currency = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Employee Posting Group" = R,
                  tabledata "Extended Text Header" = R,
                  tabledata "Extended Text Line" = R,
                  tabledata "FA Allocation" = R,
                  tabledata "FA Posting Group" = R,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Account Category" = R,
                  tabledata "G/L Account Where-Used" = R,
                  tabledata "G/L Account Source Currency" = R,
                  tabledata "G/L Entry - VAT Entry Link" = R,
                  tabledata "G/L Entry" = R,
                  tabledata "Gen. Jnl. Allocation" = R,
                  tabledata "Gen. Journal Batch" = R,
                  tabledata "Gen. Journal Template" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata "Job Posting Group" = R,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Entry" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Vendor Posting Group" = R;
}
