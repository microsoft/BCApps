namespace Microsoft.Integration.MDM;

using System.Upgrade;

/// <summary>
/// Codeunit Master Data Mgt. Install (ID 7243).
/// </summary>
codeunit 7243 "Master Data Mgt. Install"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        MasterDataMgtUpgrade: Codeunit "Master Data Mgt. Upgrade";
    begin
        // Fresh install (incl. package/base-image build) never fires the upgrade trigger, so publish the source endpoint here too.
        MasterDataMgtUpgrade.RegisterCrossEnvSourceWebService();
    end;

    trigger OnInstallAppPerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        // Only a genuine first install (no preserved data) may skip the historical per-company migrations. A reinstall
        // over preserved data keeps DataVersion non-zero and must let those migrations run against the existing data.
        if AppInfo.DataVersion() = Version.Create(0, 0, 0, 0) then
            UpgradeTag.SetAllUpgradeTags();
    end;
}
