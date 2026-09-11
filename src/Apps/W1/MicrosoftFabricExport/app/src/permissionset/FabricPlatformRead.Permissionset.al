namespace Microsoft.FabricExport;

using System.Fabric;

permissionset 9131 "Fabric Exp Read"
{
    Caption = 'Microsoft Fabric Export - Platform Read';
    Assignable = true;

    Permissions =
        tabledata "Tenant Fabric Setup" = R,
        tabledata "Tenant Fabric Tables" = R,
        tabledata "Tenant Fabric Companies" = R,
        tabledata "Tenant Fabric Table Fields" = R,
        tabledata "Tenant Fabric Enum Mapping" = R,
        tabledata "Tenant Fabric Export Summary" = R,
        tabledata "Tenant Fabric Export Details" = R,
        tabledata "Fabric Config Package" = R,
        tabledata "Fabric Config Package Line" = R,
        table "Fabric Config Package" = X,
        table "Fabric Config Package Line" = X,
        page "Fabric Platform Export Summary" = X,
        page "Fabric Platform Export Details" = X,
        page "Fabric API Tables" = X,
        page "Fabric API Companies" = X,
        page "Fabric API Export Summary" = X,
        page "Fabric API Export Details" = X;
}
