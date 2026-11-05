namespace Microsoft.FabricExport;

using System.Upgrade;

codeunit 48528 "Fabric Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerDatabase()
    begin
        EnsureRequiredLogTablesOnce();
    end;

    trigger OnUpgradePerCompany()
    var
        FabricInstall: Codeunit "Fabric Install";
    begin
        // RegisterPackage skips work when the package is already at the current version,
        // so it is safe and cheap to re-run this on every upgrade — this is what picks up
        // table additions/removals to the built-in MS-STD package for already-installed tenants.
        FabricInstall.EnsureMsStdPackage();
    end;

    internal procedure InitializeRequiredLogTables()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        FabricPlatformMgt.EnsureRequiredLogTables();
        UpgradeTag.SetDatabaseUpgradeTag(RequiredLogTablesUpgradeTag());
    end;

    local procedure EnsureRequiredLogTablesOnce()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(RequiredLogTablesUpgradeTag()) then
            exit;

        if not FabricPlatformMgt.TryEnsureRequiredLogTables(true) then
            exit;

        UpgradeTag.SetDatabaseUpgradeTag(RequiredLogTablesUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(RequiredLogTablesUpgradeTag());
    end;

    local procedure RequiredLogTablesUpgradeTag(): Code[250]
    begin
        exit(RequiredLogTablesUpgradeTagLbl);
    end;

    var
        RequiredLogTablesUpgradeTagLbl: Label 'MS-13556-EnsureRequiredLogTables-20261105', Locked = true;
}
