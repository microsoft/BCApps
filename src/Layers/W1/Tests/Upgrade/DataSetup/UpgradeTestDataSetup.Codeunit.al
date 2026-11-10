using Microsoft.Foundation.Address;
using System.Reflection;
using System.Upgrade;

codeunit 132802 "Upgrade Test Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupSEPACountryRegions()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        CountryRegionRef: RecordRef;
        AlreadyMigrated: Boolean;
    begin
        CountryRegionRef.Open(Database::"Country/Region");
        if not CountryRegionRef.DataPerCompany() then
            exit;
        CountryRegionRef.Close();

        AlreadyMigrated := UpgradeTag.HasUpgradeTag('MS-SEPACountryRegionW1-20261110');
        SetupSEPACountryRegion('UPG-SEPA-Y', true, AlreadyMigrated);
        SetupSEPACountryRegion('UPG-SEPA-N', false, AlreadyMigrated);
    end;

    local procedure SetupSEPACountryRegion(CountryCode: Code[10]; SEPAAllowed: Boolean; AlreadyMigrated: Boolean)
    var
        CountryRegion: Record "Country/Region";
        LegacyField: Record Field;
        SharedField: Record Field;
        CountryRegionRef: RecordRef;
        SEPAFieldRef: FieldRef;
        HasLegacyField: Boolean;
        CanWriteLegacyField: Boolean;
        ExpectedSEPAAllowed: Boolean;
    begin
        HasLegacyField := FindLegacySEPAField(LegacyField);
        CanWriteLegacyField := HasLegacyField and (LegacyField.ObsoleteState <> LegacyField.ObsoleteState::Removed);
        ExpectedSEPAAllowed := SEPAAllowed;
        if not AlreadyMigrated then
            if HasLegacyField then begin
                if not CanWriteLegacyField then
                    ExpectedSEPAAllowed := false;
            end else
                if not SharedField.Get(Database::"Country/Region", 13) then
                    ExpectedSEPAAllowed := false;

        if CountryRegion.Get(CountryCode) then
            CountryRegion.Delete();
        CountryRegion.Init();
        CountryRegion.Code := CountryCode;
        // The expectation must survive an upgrade from a version without the shared field.
        CountryRegion.Name := Format(ExpectedSEPAAllowed, 0, 9);
        CountryRegion."Last Modified Date Time" := CreateDateTime(20260101D, 010203T);
        CountryRegion.Insert();

        CountryRegionRef.GetTable(CountryRegion);
        if CanWriteLegacyField then begin
            SEPAFieldRef := CountryRegionRef.Field(LegacyField."No.");
            SEPAFieldRef.Value := SEPAAllowed;
        end;
        if CountryRegionRef.FieldExist(13) then begin
            SEPAFieldRef := CountryRegionRef.Field(13);
            SEPAFieldRef.Value := ExpectedSEPAAllowed;
        end;
        CountryRegionRef.Modify();
    end;

    local procedure FindLegacySEPAField(var LegacyField: Record Field): Boolean
    begin
        if LegacyField.Get(Database::"Country/Region", 10800) then
            exit(true);
        if LegacyField.Get(Database::"Country/Region", 11400) then
            exit(true);
        if LegacyField.Get(Database::"Country/Region", 13400) then
            exit(true);
        exit(LegacyField.Get(Database::"Country/Region", 2000005));
    end;

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
        WarehouseRequest.SetFilter("Source No.", '%1|%2', 'UPG-JOB-01', 'UPG-SALES-01');
        WarehouseRequest.DeleteAll();

        // Legacy Job row that MUST be renamed to (Database::"Job Planning Line", Order) by the upgrade.
        WarehouseRequest.Init();
        WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
        WarehouseRequest."Location Code" := '';
        WarehouseRequest."Source Type" := Database::Job;
        WarehouseRequest."Source Subtype" := 0;
        WarehouseRequest."Source No." := 'UPG-JOB-01';
        WarehouseRequest.Insert();

        // Non-job row (Sales Header) that MUST NOT be touched by the upgrade. Guards against a regression
        // where the Warehouse Request FindSet() loop iterates without a Source Type / Source Subtype filter.
        WarehouseRequest.Init();
        WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
        WarehouseRequest."Location Code" := '';
        WarehouseRequest."Source Type" := Database::"Sales Header";
        WarehouseRequest."Source Subtype" := 1; // Sales Order
        WarehouseRequest."Source No." := 'UPG-SALES-01';
        WarehouseRequest.Insert();
    end;
}