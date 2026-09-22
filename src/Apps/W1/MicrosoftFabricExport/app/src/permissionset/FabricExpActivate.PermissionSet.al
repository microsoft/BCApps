namespace Microsoft.FabricExport;

using System.Fabric;

permissionset 48532 "Fabric Exp Activate"
{
    Caption = 'MS Fabric Export - Activate', MaxLength = 30;
    Assignable = true;

    Permissions =
        table "Fabric Config Package" = X,
        tabledata "Fabric Config Package" = RM,
        table "Fabric Config Package Line" = X,
        tabledata "Fabric Config Package Line" = R,
        tabledata "Fabric Table Claim" = R,
        tabledata "Tenant Fabric Companies" = R,
        tabledata "Tenant Fabric Enum Mapping" = R,
        tabledata "Tenant Fabric Export Details" = R,
        tabledata "Tenant Fabric Export Summary" = R,
        tabledata "Tenant Fabric Setup" = R,
        tabledata "Tenant Fabric Table Fields" = R,
        tabledata "Tenant Fabric Tables" = Rim,
        codeunit "Fabric Config Package Mgt" = X,
        codeunit "Fabric Platform Admin Client" = X,
        codeunit "Fabric Platform Credential Mgt" = X,
        codeunit "Fabric Platform Http Client" = X,
        codeunit "Fabric Platform Lookup State" = X,
        codeunit "Fabric Platform Mgt" = X,
        codeunit "Fabric Platform Telemetry" = X,
        page "Fabric Companies FactBox" = X,
        page "Fabric Config Package Card" = X,
        page "Fabric Config Packages" = X,
        page "Fabric Config Package Subform" = X,
        page "Fabric Platform Setup" = X,
        page "Fabric Tables FactBox" = X;
}
