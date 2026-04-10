namespace System.Security.AccessControl;

using Microsoft.CRM.Duplicates;

permissionset 5783 "MERGE DUPLICATES"
{
    Access = Public;
    Assignable = true;
    Caption = 'Merge Duplicates';

    Permissions = tabledata "Merge Duplicates Buffer" = RIMD,
                  tabledata "Merge Duplicates Conflict" = RIMD,
                  tabledata "Merge Duplicates Line Buffer" = RIMD;
}
