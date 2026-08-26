namespace Microsoft.Integration.MDM;

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
}
