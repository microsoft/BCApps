namespace System.Security.AccessControl;

using System.DataAdministration;

permissionsetextension 649 "Reten. Pol. Admin - BaseApp" extends "Retention Pol. Admin"
{
    // "Reten. Pol. Setup - BaseApp" is defined in this application; including it here
    // is how the Base Application contributes its retention policy permissions.
#pragma warning disable AS0112
    IncludedPermissionSets = "Reten. Pol. Setup - BaseApp";
#pragma warning restore AS0112
}
