namespace Microsoft.FabricExport;

codeunit 48528 "Fabric Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    var
        FabricInstall: Codeunit "Fabric Install";
    begin
        // RegisterPackage skips work when a package is already at the current version,
        // so it is safe and cheap to re-run this on every upgrade. This also migrates
        // tenants from the legacy MS-STD package to the domain-specific packages.
        FabricInstall.EnsureMicrosoftPackages();
    end;
}
