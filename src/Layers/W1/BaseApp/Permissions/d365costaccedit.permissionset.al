namespace System.Security.AccessControl;

using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Journal;

permissionset 2073 "D365 COSTACC, EDIT"
{
    Assignable = true;
    Caption = 'Dyn. 365 Edit Cost Accounting';

    IncludedPermissionSets = "D365 COSTACC, VIEW";

    Permissions = tabledata "Cost Allocation Source" = IMD,
                  tabledata "Cost Allocation Target" = IMD,
                  tabledata "Cost Budget Buffer" = imd,
                  tabledata "Cost Budget Entry" = IMD,
                  tabledata "Cost Budget Name" = IMD,
                  tabledata "Cost Budget Register" = IMD,
                  tabledata "Cost Center" = IMD,
                  tabledata "Cost Entry" = IMD,
                  tabledata "Cost Journal Batch" = IMD,
                  tabledata "Cost Journal Line" = IMD,
                  tabledata "Cost Journal Template" = IMD,
                  tabledata "Cost Object" = IMD,
                  tabledata "Cost Register" = IMD,
                  tabledata "Cost Type" = IMD;
}
