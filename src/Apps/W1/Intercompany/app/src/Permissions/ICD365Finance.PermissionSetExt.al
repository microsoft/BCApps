namespace System.Security.AccessControl;

permissionsetextension 8417 "IC D365 FINANCE" extends "D365 FINANCE"
{
#pragma warning disable AA0052, PTE0018 // Accepted: Preserve the existing General Ledger Setup and VAT Setup permissions after the Intercompany extraction.
    IncludedPermissionSets = "D365 IC, EDIT",
                             "D365 IC, SETUP",
                             "D365 IC, VIEW";
#pragma warning restore AA0052, PTE0018
}
