namespace Microsoft.FabricExport;

using System.Fabric;

#if not PTE
permissionset 150003 "Fabric Plat Activate"
#else
permissionset 50103 "Fabric Plat Activate"
#endif
{
    Caption = 'Microsoft Fabric Export - Platform Activate';
    Assignable = true;

    Permissions =
        tabledata "Tenant Fabric Setup" = R,
        tabledata "Tenant Fabric Tables" = RIM,
        tabledata "Tenant Fabric Table Fields" = R,
        tabledata "Tenant Fabric Enum Mapping" = R,
        tabledata "Tenant Fabric Export Summary" = R,
        tabledata "Tenant Fabric Export Details" = R,
        tabledata "Fabric Config Package" = RM,
        tabledata "Fabric Config Package Line" = R,
        table "Fabric Config Package" = X,
        table "Fabric Config Package Line" = X,
        codeunit "Fabric Platform Mgt" = X,
        codeunit "Fabric Config Package Mgt" = X,
        codeunit "Fabric Platform Telemetry" = X,
        page "Fabric Platform Setup" = X,
        page "Fabric Config Packages" = X,
        page "Fabric Config Package Card" = X,
        page "Fabric Config Package Subform" = X;
}
