namespace Microsoft.Integration.Shopify;

using System.Upgrade;

/// <summary>
/// Codeunit Shpfy TMA Upgrade (ID 30478).
/// Backfills the tax configuration defaults onto Shop records that already existed
/// before the fields were added. The work is guarded by an upgrade tag so it runs exactly once
/// per company, and is shared between the install path (new install into a company that already
/// has shops) and the upgrade path (a previously installed app being updated).
/// </summary>
codeunit 30478 "Shpfy TMA Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;
    Permissions = tabledata "Shpfy Shop" = RM;

    trigger OnUpgradePerCompany()
    begin
        BackfillShopDefaults();
    end;

    /// <summary>
    /// New Shop records pick up the tax defaults from the field InitValues, but Shop
    /// records that already exist when this app is installed keep the platform zero-values
    /// ('' / false). Backfill the InitValue-backed fields (Tax Area auto-creation on, blocking
    /// review on, standard Tax Area naming prefix) so existing shops start with the same defaults
    /// new shops get. Reading the values from an Init()'d record keeps this in sync with the
    /// tableextension InitValues without duplicating the literals. The upgrade tag makes this run
    /// exactly once per company; the tag is intentionally NOT registered in
    /// OnGetPerCompanyUpgradeTags so a fresh install (which has no tag yet) still runs it against
    /// any shops that already exist. The two intentionally-false defaults (Tax Matching Agent
    /// Enabled, Auto Create Tax Jurisdictions) are left untouched.
    /// </summary>
    internal procedure BackfillShopDefaults()
    var
        Shop: Record "Shpfy Shop";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetShopDefaultsUpgradeTag()) then
            exit;

        if Shop.FindSet(true) then
            repeat
                ApplyShopDefaults(Shop);
                Shop.Modify();
            until Shop.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetShopDefaultsUpgradeTag());
    end;

    /// <summary>
    /// Sets the InitValue-backed tax defaults on a single Shop. Reading them from an
    /// Init()'d record keeps this in sync with the tableextension InitValues without duplicating
    /// the literals. Does not Modify — the caller decides when to persist.
    /// </summary>
    internal procedure ApplyShopDefaults(var Shop: Record "Shpfy Shop")
    var
        DefaultShop: Record "Shpfy Shop";
    begin
        DefaultShop.Init();
        Shop."Auto Create Tax Areas" := DefaultShop."Auto Create Tax Areas";
        Shop."Tax Area Naming Pattern" := DefaultShop."Tax Area Naming Pattern";
        Shop."Tax Match Review Required" := DefaultShop."Tax Match Review Required";
    end;

    internal procedure GetShopDefaultsUpgradeTag(): Code[250]
    begin
        exit('MS-445769-TMAShopDefaults-20260720');
    end;
}
