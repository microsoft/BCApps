namespace System.Security.AccessControl;

using Microsoft.Finance.Consolidation;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

permissionset 3706 "General Ledger Budget - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit G/L budgets';

    Permissions = tabledata "Business Unit" = R,
                  tabledata "Business Unit Information" = R,
                  tabledata "Business Unit Setup" = R,
                  tabledata "Comment Line" = RI,
                  tabledata "Consolidation Account" = R,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Budget Entry" = RIMD,
                  tabledata "G/L Budget Name" = RIMD;
}
