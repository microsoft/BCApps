namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Copilot Tax Install (ID 30475).
/// Install codeunit that registers the Copilot capability and backfills the Copilot tax
/// configuration defaults onto Shop records that already exist when the app is installed.
/// </summary>
codeunit 30475 "Shpfy Copilot Tax Install"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
    begin
        CopilotTaxRegister.RegisterCopilotCapability();
    end;

    trigger OnInstallAppPerCompany()
    var
        CopilotTaxUpgrade: Codeunit "Shpfy Copilot Tax Upgrade";
    begin
        // Shop records that already exist when the app is installed keep the field zero-values
        // instead of the InitValues; the same tag-guarded backfill the upgrade path uses brings
        // them to the defaults. The upgrade tag makes this run exactly once per company.
        CopilotTaxUpgrade.BackfillShopDefaults();
    end;
}
