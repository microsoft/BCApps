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
    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupLegacyWhseActivityLineForJobSource()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("No.", 'UPG-WHACT-J01');
        WarehouseActivityLine.DeleteAll();

        WarehouseActivityLine.Init();
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."No." := 'UPG-WHACT-J01';
        WarehouseActivityLine."Line No." := 10000;
        WarehouseActivityLine."Source Type" := Database::Job;
        WarehouseActivityLine."Source Subtype" := 0;
        WarehouseActivityLine."Source No." := 'UPG-JOB-01';
        WarehouseActivityLine.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupLegacyWhseWorksheetLineForJobSource()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", 'UPGWHT');
        WhseWorksheetLine.SetRange(Name, 'UPGWSN');
        WhseWorksheetLine.DeleteAll();

        WhseWorksheetLine.Init();
        WhseWorksheetLine."Worksheet Template Name" := 'UPGWHT';
        WhseWorksheetLine.Name := 'UPGWSN';
        WhseWorksheetLine."Location Code" := '';
        WhseWorksheetLine."Line No." := 10000;
        WhseWorksheetLine."Source Type" := Database::Job;
        WhseWorksheetLine."Source Subtype" := 0;
        WhseWorksheetLine."Source No." := 'UPG-JOB-01';
        WhseWorksheetLine.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupLegacyWarehouseRequestForJobSource()
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Source No.", 'UPG-JOB-01');
        WarehouseRequest.DeleteAll();

        WarehouseRequest.Init();
        WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
        WarehouseRequest."Location Code" := '';
        WarehouseRequest."Source Type" := Database::Job;
        WarehouseRequest."Source Subtype" := 0;
        WarehouseRequest."Source No." := 'UPG-JOB-01';
        WarehouseRequest.Insert();
    end;
}