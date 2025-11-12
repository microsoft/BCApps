namespace System.Security.AccessControl;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

permissionset 5417 "Account Schedules - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read account schedules';

    Permissions = tabledata "Acc. Schedule Line" = R,
                  tabledata "Acc. Schedule Name" = RI,
                  tabledata "Financial Report" = RI,
                  tabledata "Financial Report Export Log" = R,
                  tabledata "Financial Report Recipient" = R,
                  tabledata "Financial Report Schedule" = R,
                  tabledata "Financial Report User Filters" = RIMD,
                  tabledata "Fin. Report Excel Template" = RIMD,
                  tabledata "Analysis View" = R,
                  tabledata "Analysis View Budget Entry" = R,
                  tabledata "Analysis View Entry" = R,
                  tabledata "Business Unit" = R,
                  tabledata "Business Unit Information" = R,
                  tabledata "Business Unit Setup" = R,
                  tabledata "Column Layout" = R,
                  tabledata "Column Layout Name" = R,
                  tabledata "Consolidation Account" = R,
                  tabledata Dimension = R,
                  tabledata "Dimension Value" = R,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Budget Name" = R;
}
