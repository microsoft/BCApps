namespace System.Security.AccessControl;

using System.Reflection;
using System.Environment.Configuration;
using System.Tooling;

permissionset 2581 "D365 PROFILE MGT"
{
    Access = Public;
    Assignable = true;
    Caption = 'D365 Profile Mgt & Customiz.';

    IncludedPermissionSets = "Metadata - Read";

    Permissions = tabledata "All Profile" = IMD,
                  tabledata "All Profile Extension" = IMD,
                  tabledata "All Profile Page Metadata" = IMD,
                  tabledata "Profile Configuration Symbols" = IMD,
                  tabledata "Tenant Profile" = IMD,
                  tabledata "Tenant Profile Extension" = IMD,
                  tabledata "Tenant Profile Page Metadata" = IMD,
                  tabledata "Tenant Profile Setting" = IMD,
                  tabledata "Designer Diagnostic" = RIMD,
                  tabledata "Profile Designer Diagnostic" = RIMD,
                  tabledata "Profile Import" = RIMD,
                  system "Add Table Field To Page" = X;
}
