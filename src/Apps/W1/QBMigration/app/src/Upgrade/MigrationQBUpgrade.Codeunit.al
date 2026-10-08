#pragma warning disable AA0247
codeunit 1831 "MigrationQB Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany();
    begin
        DeleteArchiveData();
        SendQuickBooksMigrationTelemetry();
    end;

    local procedure DeleteArchiveData()
    begin
        NavApp.DeleteArchiveData(1911);
        NavApp.DeleteArchiveData(1912);
        NavApp.DeleteArchiveData(1913);
        NavApp.DeleteArchiveData(1914);
        NavApp.DeleteArchiveData(1915);
        NavApp.DeleteArchiveData(1916);
        NavApp.DeleteArchiveData(1917);
        NavApp.DeleteArchiveData(1918);
    end;

    local procedure SendQuickBooksMigrationTelemetry()
    var
        MigrationQBDashboardMgt: Codeunit "MigrationQB Dashboard Mgt";
        UpgradeTag: Codeunit "Upgrade Tag";
        MigrationDateTime: DateTime;
    begin
        if UpgradeTag.HasUpgradeTag(GetSendQuickBooksMigrationTelemetryTag()) then
            exit;

        if MigrationQBDashboardMgt.GetCompletedMigrationDateTime(MigrationDateTime) then
            MigrationQBDashboardMgt.SendCompletedMigrationTelemetry(MigrationDateTime);

        UpgradeTag.SetUpgradeTag(GetSendQuickBooksMigrationTelemetryTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetSendQuickBooksMigrationTelemetryTag());
    end;

    local procedure GetSendQuickBooksMigrationTelemetryTag(): Text[250]
    begin
        exit('MS-QuickBooksMigrationUptake-20260930');
    end;
}
