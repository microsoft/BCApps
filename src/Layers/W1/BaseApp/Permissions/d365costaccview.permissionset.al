namespace System.Security.AccessControl;

using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Journal;
using Microsoft.Finance.GeneralLedger.Account;

permissionset 5269 "D365 COSTACC, VIEW"
{
    Assignable = true;

    Caption = 'Dyn. 365 View Cost Accounting';
    Permissions = tabledata "Cost Allocation Source" = R,
                  tabledata "Cost Allocation Target" = R,
                  tabledata "Cost Budget Buffer" = R,
                  tabledata "Cost Budget Entry" = R,
                  tabledata "Cost Budget Name" = R,
                  tabledata "Cost Budget Register" = R,
                  tabledata "Cost Center" = R,
                  tabledata "Cost Entry" = R,
                  tabledata "Cost Journal Batch" = R,
                  tabledata "Cost Journal Line" = R,
                  tabledata "Cost Journal Template" = R,
                  tabledata "Cost Object" = R,
                  tabledata "Cost Register" = R,
                  tabledata "Cost Type" = R,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Account Source Currency" = R;
}
