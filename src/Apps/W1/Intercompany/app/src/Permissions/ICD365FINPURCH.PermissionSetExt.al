namespace System.Security.AccessControl;

permissionsetextension 8418 "IC D365 FIN. & PURCH." extends "D365 FIN. & PURCH."
{
#pragma warning disable AA0052, PTE0018 // Accepted: Preserve the existing General Ledger Setup and VAT Setup permissions after the Intercompany extraction.
    IncludedPermissionSets = "D365 IC, EDIT",
                             "D365 IC, SETUP",
                             "D365 IC, VIEW";
#pragma warning restore AA0052, PTE0018
}
