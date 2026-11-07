namespace System.Security.AccessControl;

permissionsetextension 4913 "IC D365 SALES" extends "D365 SALES"
{
#pragma warning disable AA0052, PTE0018 // Accepted: Preserve the existing General Ledger Setup and VAT Setup permissions after the Intercompany extraction.
    IncludedPermissionSets = "D365 IC, EDIT",
                             "D365 IC, VIEW";
#pragma warning restore AA0052, PTE0018
}
