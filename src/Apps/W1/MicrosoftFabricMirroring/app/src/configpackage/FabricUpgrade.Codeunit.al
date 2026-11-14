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
        FabricInstall.RegisterMicrosoftPackages();
        UpgradeLegacyMicrosoftPackage();
    end;

    local procedure UpgradeLegacyMicrosoftPackage()
    var
        FabricInstall: Codeunit "Fabric Install";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetLegacyPackageMigrationTag()) then
            exit;

        // A capacity-deferred migration must remain eligible for the next upgrade.
        if not FabricInstall.MigrateLegacyMicrosoftPackage() then
            exit;

        UpgradeTag.SetUpgradeTag(GetLegacyPackageMigrationTag());
    end;

    internal procedure GetLegacyPackageMigrationTag(): Code[250]
    var
        LegacyPackageMigrationTagLbl: Label 'MS-13720-MigrateLegacyFabricPackage-20261110', Locked = true;
    begin
        exit(LegacyPackageMigrationTagLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        RegisterPerCompanyUpgradeTags(PerCompanyUpgradeTags);
    end;

    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetLegacyPackageMigrationTag());
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
