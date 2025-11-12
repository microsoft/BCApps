namespace System.Security.AccessControl;

using Microsoft.Finance.Consolidation;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

permissionset 516 "General Ledger Budget - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read G/L budgets';

    Permissions = tabledata "Business Unit" = R,
                  tabledata "Business Unit Information" = R,
                  tabledata "Business Unit Setup" = R,
                  tabledata "Comment Line" = R,
                  tabledata "Consolidation Account" = R,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Budget Entry" = R,
                  tabledata "G/L Budget Name" = RI;
}
