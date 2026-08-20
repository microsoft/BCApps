namespace Microsoft.Bc2Fabric;

using System.Fabric;

permissionset 150001 "Fabric Plat Admin"
{
    Caption = 'BC2Fabric - Platform Admin';
    Assignable = true;

    Permissions =
        tabledata "Tenant Fabric Setup" = RIMD,
        tabledata "Tenant Fabric Tables" = RIMD,
        tabledata "Tenant Fabric Companies" = RIMD,
        tabledata "Tenant Fabric Table Fields" = RIMD,
        tabledata "Tenant Fabric Enum Mapping" = R,
        tabledata "Tenant Fabric Export Summary" = R,
        tabledata "Tenant Fabric Export Details" = R,
        tabledata "Fabric Config Package" = RIMD,
        tabledata "Fabric Config Package Line" = RIMD,
        table "Fabric Config Package" = X,
        table "Fabric Config Package Line" = X,
        codeunit "Fabric Platform Mgt" = X,
        codeunit "Fabric Config Package Mgt" = X,
        codeunit "Fabric Install" = X,
        page "Fabric Platform Setup" = X,
        page "Fabric Platform Tables" = X,
        page "Fabric Platform Companies" = X,
        page "Fabric Platform Export Summary" = X,
        page "Fabric Platform Export Details" = X,
        page "Fabric Config Packages" = X,
        page "Fabric Config Package Card" = X,
        page "Fabric Config Package Subform" = X;
}
