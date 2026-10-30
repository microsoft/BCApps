namespace System.Security.AccessControl;

permissionsetextension 8419 "IC D365 BUS FULL ACCESS" extends "D365 BUS FULL ACCESS"
{
#pragma warning disable AA0052, PTE0018 // Accepted: Preserve the existing General Ledger Setup and VAT Setup permissions after the Intercompany extraction.
    IncludedPermissionSets = "D365 IC, EDIT",
                             "D365 IC, SETUP";
#pragma warning restore AA0052, PTE0018
}
