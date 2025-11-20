namespace System.Security.AccessControl;

using Microsoft.Projects.Project.Job;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Project.WIP;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Inventory.Item;

permissionset 5679 "Jobs - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Project periodic activities';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata "Analysis View" = rimd,
                  tabledata "Analysis View Entry" = rim,
                  tabledata "Analysis View Filter" = r,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata Currency = R,
                  tabledata "Date Compr. Register" = Rim,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Entry - VAT Entry Link" = RI,
                  tabledata "G/L Entry" = Rim,
                  tabledata "G/L Register" = Rim,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata Job = RM,
                  tabledata "Job Ledger Entry" = Rimd,
                  tabledata "Job Planning Line - Calendar" = RIMD,
                  tabledata "Job Planning Line" = RIMD,
                  tabledata "Job Posting Buffer" = RIMD,
                  tabledata "Job Posting Group" = R,
                  tabledata "Job Register" = Rimd,
                  tabledata "Job Task" = RIMD,
                  tabledata "Job WIP Entry" = Rimd,
                  tabledata "Job WIP G/L Entry" = Rimd,
                  tabledata "Source Code Setup" = R,
                  tabledata "VAT Entry" = RI,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Setup" = R;
}
