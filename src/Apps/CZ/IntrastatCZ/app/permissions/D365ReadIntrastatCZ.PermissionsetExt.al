#pragma warning disable AA0247
permissionsetextension 31304 "D365 READ - Intrastat CZ" extends "D365 READ"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Intrastat CZ - Read";
#pragma warning restore AA0052, PTE0018
}
