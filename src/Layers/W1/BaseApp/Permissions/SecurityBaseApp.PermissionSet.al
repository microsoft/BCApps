namespace System.Security.AccessControl;

using System.Environment.Configuration;
using System.Diagnostics;
using Microsoft.Foundation.Company;
using System.Tooling;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Privacy;
using System.Security.User;
using Microsoft.Utilities;
using Microsoft.Finance.VAT.Setup;
using Microsoft;

permissionset 7372 "Security - Baseapp"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Assign permissions to users';

    IncludedPermissionSets = "Agent - Admin",
                             "Agent - Diagnostics",
                             "BaseApp Objects - Exec";

    Permissions = tabledata "AAD Application" = RIMD,
                  tabledata "Activity Log" = RIMD,
                  tabledata "Application Area Setup" = R,
                  tabledata "Change Log Entry" = Rimd,
                  tabledata "Company Information" = R,
                  tabledata "Designer Diagnostic" = RIMD,
                  tabledata "Experience Tier Setup" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "Permission Buffer" = RIMD,
                  tabledata "Permission Set Buffer" = RIMD,
                  tabledata "Permission Set Link" = rimd,
                  tabledata "Profile Designer Diagnostic" = RIMD,
                  tabledata "Profile Import" = RIMD,
                  tabledata "Support Contact Information" = Rimd,
                  tabledata "Terms And Conditions" = RIM,
                  tabledata "Terms And Conditions State" = RIM,
                  tabledata "User Security Status" = RIMD;
}
