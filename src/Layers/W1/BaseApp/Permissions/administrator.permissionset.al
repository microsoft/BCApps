namespace System.Security.AccessControl;

using System.Email;
using System.Apps;
using System.DataAdministration;

permissionset 2914 "Administrator"
{
    Assignable = true;

    Caption = 'Create and set up companies';

    IncludedPermissionSets = "D365 BASIC",
                             "D365 COSTACC, SETUP",
                             "D365 FA, SETUP",
                             "D365 HR, SETUP",
                             "D365 IC, SETUP",
                             "D365 INV, SETUP",
                             "D365 JOBS, EDIT",
                             "D365 RM SETUP",
                             "D365 SETUP",
                             "D365 WEBHOOK SUBSCR",
                             "EMAIL - ADMIN",
                             "EXTEN. MGT. - ADMIN",
                             "MERGE DUPLICATES",
                             "RETENTION POL. ADMIN",
                             "TEST TOOL";
}