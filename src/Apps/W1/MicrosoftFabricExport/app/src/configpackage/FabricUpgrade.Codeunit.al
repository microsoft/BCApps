namespace Microsoft.FabricExport;

codeunit 9109 "Fabric Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    var
        FabricInstall: Codeunit "Fabric Install";
    begin
        // RegisterPackage skips work when the package is already at the current version,
        // so it is safe and cheap to re-run this on every upgrade — this is what picks up
        // table additions/removals to the built-in MS-STD package for already-installed tenants.
        FabricInstall.EnsureMsStdPackage();
    end;
}
