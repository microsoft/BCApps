namespace System.Security.AccessControl;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

permissionset 3632 "Account Schedules - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit account schedules';

    Permissions = tabledata "Acc. Sched. Chart Setup Line" = RIMD,
                  tabledata "Acc. Schedule Line" = RIMD,
                  tabledata "Acc. Schedule Name" = RIMD,
                  tabledata "Financial Report" = RIMD,
                  tabledata "Financial Report Export Log" = RIMD,
                  tabledata "Financial Report Recipient" = RIMD,
                  tabledata "Financial Report Schedule" = RIMD,
                  tabledata "Financial Report User Filters" = RIMD,
                  tabledata "Fin. Report Excel Template" = RIMD,
                  tabledata "Account Schedules Chart Setup" = RIMD,
                  tabledata "Analysis View" = R,
                  tabledata "Analysis View Budget Entry" = R,
                  tabledata "Analysis View Entry" = R,
                  tabledata "Business Unit" = R,
                  tabledata "Business Unit Information" = R,
                  tabledata "Business Unit Setup" = R,
                  tabledata "Column Layout" = RIMD,
                  tabledata "Column Layout Name" = RIMD,
                  tabledata "Consolidation Account" = R,
                  tabledata Dimension = R,
                  tabledata "Dimension Value" = R,
                  tabledata "G/L Account Category" = RIMD,
                  tabledata "G/L Budget Name" = RI;
}
