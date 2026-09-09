namespace Microsoft.FabricExport;

using System.Fabric;

#if not PTE
permissionset 150002 "Fabric Exp Read"
#else
permissionset 50102 "Fabric Exp Read"
#endif
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
        page "Fabric Platform Setup" = X,
        page "Fabric Platform Name Lookup" = X,
        page "Fabric Platform Tables" = X,
        page "Fabric Platform Companies" = X,
        page "Fabric Platform Export Summary" = X,
        page "Fabric Platform Export Details" = X,
        page "Fabric Config Packages" = X,
        page "Fabric Config Package Card" = X,
        page "Fabric Config Package Subform" = X,
        page "Fabric API Tables" = X,
        page "Fabric API Companies" = X,
        page "Fabric API Config Packages" = X,
        page "Fabric API Export Summary" = X,
        page "Fabric API Export Details" = X,
        page "Fabric API Setup" = X;
}
