codeunit 132801 "Upgrade Codeunit - Data Setup"
{
    Subtype = Upgrade;

    trigger OnCheckPreconditionsPerCompany()
    var
        UpgradeTestDataSetup: Codeunit "Upgrade Test Data Setup Mgt.";
        UpgradeStatus: codeunit "Upgrade Status";
    begin
        if (UpgradeStatus.RunUpgradePerDatabaseTriggers()) then begin
            UpgradeTestDataSetup.OnSetupDataPerDatabase();
            UpgradeTestDataSetup.BackupTablesPerDatabase();
        end;

        UpgradeTestDataSetup.OnSetupDataPerCompany();
        UpgradeTestDataSetup.BackupTablesPerCompany();
        SetUpgradeTriggered();
    end;

    procedure SetUpgradeTriggered()
    var
        UpgradeStatus: Codeunit "Upgrade Status";
    begin
        UpgradeStatus.SetUpgradeStatusTriggered();
    end;
}