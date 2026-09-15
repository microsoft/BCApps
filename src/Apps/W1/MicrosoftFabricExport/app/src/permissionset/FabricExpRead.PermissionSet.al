namespace Microsoft.FabricExport;

using System.Fabric;

permissionset 48531 "Fabric Exp Read"
{
    Caption = 'MS Fabric Export - Read', MaxLength = 30;
    Assignable = true;

    Permissions =
        table "Fabric Config Package" = X,
        tabledata "Fabric Config Package" = R,
        table "Fabric Config Package Line" = X,
        tabledata "Fabric Config Package Line" = R,
        tabledata "Fabric Table Claim" = R,
        tabledata "Tenant Fabric Companies" = R,
        tabledata "Tenant Fabric Enum Mapping" = R,
        tabledata "Tenant Fabric Export Details" = R,
        tabledata "Tenant Fabric Export Summary" = R,
        tabledata "Tenant Fabric Setup" = R,
        tabledata "Tenant Fabric Table Fields" = R,
        tabledata "Tenant Fabric Tables" = R,
        page "Fabric API Export Details" = X,
        page "Fabric API Export Summary" = X,
        page "Fabric Platform Export Details" = X,
        page "Fabric Platform Export Summary" = X;
}
