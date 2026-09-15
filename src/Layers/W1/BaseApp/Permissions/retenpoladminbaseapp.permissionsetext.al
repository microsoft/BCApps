namespace System.Security.AccessControl;

using System.DataAdministration;

permissionsetextension 649 "Reten. Pol. Admin - BaseApp" extends "Retention Pol. Admin"
{
#pragma warning disable AA0052, PTE0018 // Accepted: The existing cross-application inclusion must remain to preserve the current permission composition.
    IncludedPermissionSets = "Reten. Pol. Setup - BaseApp";
#pragma warning restore AA0052, PTE0018
}
