namespace Microsoft.FabricExport;

using System.DataAdministration;

codeunit 48500 "Fabric Env. Cleanup Subs."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", OnClearDatabaseConfig, '', false, false)]
    local procedure OnClearDatabaseConfig(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.ClearCopiedEnvironmentConfiguration();
    end;
}
