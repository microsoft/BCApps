#pragma warning disable AA0247
permissionsetextension 31303 "D365 BASIC ISV - Intrastat CZ" extends "D365 BASIC ISV"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Intrastat CZ - Edit";
#pragma warning restore AA0052, PTE0018
}
