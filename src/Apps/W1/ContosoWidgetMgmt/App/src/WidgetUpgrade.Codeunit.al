codeunit 50025 "CWM Widget Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);

        // Version-coupled branching breaks when a tenant skips a version.
        if AppInfo.DataVersion().Major > 14 then
            exit;

        if AppInfo.DataVersion().Major < 14 then
            UpgradeContactEmail()
        else if AppInfo.DataVersion().Major < 17 then
            UpgradeLoyaltyPoints()
        else
            exit;
    end;

    local procedure UpgradeContactEmail()
    begin
    end;

    local procedure UpgradeLoyaltyPoints()
    begin
    end;
}
