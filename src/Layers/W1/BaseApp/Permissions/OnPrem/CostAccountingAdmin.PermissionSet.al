namespace System.Security.AccessControl;

using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Journal;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.CostAccounting.Setup;

permissionset 3008 "Cost Accounting - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Cost Accounting';

    Permissions = tabledata "Cost Accounting Setup" = RIMD,
                  tabledata "Cost Allocation Source" = RIMD,
                  tabledata "Cost Allocation Target" = RIMD,
                  tabledata "Cost Budget Buffer" = RIMD,
                  tabledata "Cost Budget Entry" = Rimd,
                  tabledata "Cost Budget Name" = RIMD,
                  tabledata "Cost Budget Register" = RIMD,
                  tabledata "Cost Center" = RIMD,
                  tabledata "Cost Entry" = Rimd,
                  tabledata "Cost Journal Batch" = RIMD,
                  tabledata "Cost Journal Line" = RIMD,
                  tabledata "Cost Journal Template" = RIMD,
                  tabledata "Cost Object" = RIMD,
                  tabledata "Cost Register" = RIMD,
                  tabledata "Cost Type" = RIMD,
                  tabledata "G/L Account" = Rm,
                  tabledata "G/L Account Source Currency" = Rm,
                  tabledata "G/L Entry" = Rm;
}
