codeunit 30273 "Shpfy Installer"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    begin
        AddRetentionPolicyAllowedTables();
    end;

    procedure AddRetentionPolicyAllowedTables()
    begin
        AddRetentionPolicyAllowedTables(false);
    end;

    procedure AddRetentionPolicyAllowedTables(ForceUpdate: Boolean)
    var
        ShpfyLogEntry: Record "Shpfy Log Entry";
        RetentionPolicySetup: Codeunit "Retention Policy Setup";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        UpgradeTag: Codeunit "Upgrade Tag";
        IsInitialSetup: Boolean;
    begin
        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetShopifyLogEntryAddedToAllowedListUpgradeTag());
        if not (IsInitialSetup or ForceUpdate) then
            exit;

        RetenPolAllowedTables.AddAllowedTable(Database::"Shpfy Log Entry", ShpfyLogEntry.FieldNo(SystemCreatedAt));

        if not IsInitialSetup then
            exit;

        CreateRetentionPolicySetup(Database::"Shpfy Log Entry", RetentionPolicySetup.FindOrCreateRetentionPeriod("Retention Period Enum"::"1 Month"));
        UpgradeTag.SetUpgradeTag(GetShopifyLogEntryAddedToAllowedListUpgradeTag());
    end;

    local procedure CreateRetentionPolicySetup(TableId: Integer; RetentionPeriodCode: Code[20])
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(TableId) then
            exit;
        RetentionPolicySetup.Validate("Table Id", TableId);
        RetentionPolicySetup.Validate("Apply to all records", true);
        RetentionPolicySetup.Validate("Retention Period", RetentionPeriodCode);
        RetentionPolicySetup.Validate(Enabled, false);
        RetentionPolicySetup.Insert(true);
    end;

    local procedure GetShopifyLogEntryAddedToAllowedListUpgradeTag(): Code[250]
    begin
        exit('MS-474464-ShopifyLogEntryAdded-20230601');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Allowed Tables", OnRefreshAllowedTables, '', false, false)]
    local procedure AddAllowedTablesOnRefreshAllowedTables()
    begin
        AddRetentionPolicyAllowedTables(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnBeforeOnRun', '', false, false)]
    local procedure AddAllowedTablesOnAfterSystemInitialization()
    begin
        AddRetentionPolicyAllowedTables();
    end;
}