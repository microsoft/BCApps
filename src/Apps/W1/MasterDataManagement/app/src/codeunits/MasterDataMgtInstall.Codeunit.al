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
    begin
        // This trigger only fires on a fresh install (never on upgrade), and a fresh company carries no legacy data:
        // mark the historical per-company migrations as done so a later app upgrade never re-runs them here.
        UpgradeTag.SetAllUpgradeTags();
    end;
}
