codeunit 132802 "Upgrade Test Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupCRMStatus()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.get() then
            CRMConnectionSetup.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnGetTablesToBackupPerCompany', '', false, false)]
    local procedure BackupIntegrationTableMapping(TableMapping: Dictionary of [Integer, Integer])
    var
        UPGIntegrationTableMapping: Record "UPG-Integration Table Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        OpportunityTableFilter: Text;
    begin
        IntegrationTableMapping.SetRange(Name, 'OPPORTUNITY');
        IntegrationTableMapping.SetRange("Table ID", Database::Opportunity);
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Opportunity");
        if IntegrationTableMapping.FindFirst() then begin
            OpportunityTableFilter := IntegrationTableMapping.GetTableFilter();
            UPGIntegrationTableMapping.Name := IntegrationTableMapping.Name;
            UPGIntegrationTableMapping.SetTableFilter(OpportunityTableFilter);
            UPGIntegrationTableMapping.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnGetTablesToBackupPerDatabase', '', false, false)]
    local procedure BackupUpgradeTags(TableMapping: Dictionary of [Integer, Integer])
    begin
        TableMapping.Add(9999, Database::"UPG - Upgrade Tag")
    end;
}