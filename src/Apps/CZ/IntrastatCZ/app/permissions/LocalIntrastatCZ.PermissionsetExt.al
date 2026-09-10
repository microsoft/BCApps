#pragma warning disable AA0247
permissionsetextension 31301 "LOCAL - Intrastat CZ" extends LOCAL
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Intrastat CZ - Read";
#pragma warning restore AA0052, PTE0018
}
