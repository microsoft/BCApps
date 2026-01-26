codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(Database::"Bank Account Buffer");
        ListOfTablesToMigrate.Add(Database::"FR Acc. Schedule Line");
        ListOfTablesToMigrate.Add(Database::"FR Acc. Schedule Name");
        ListOfTablesToMigrate.Add(Database::"Payment Address");
        ListOfTablesToMigrate.Add(Database::"Payment Class");
        ListOfTablesToMigrate.Add(Database::"Payment Header Archive");
        ListOfTablesToMigrate.Add(Database::"Payment Header");
        ListOfTablesToMigrate.Add(Database::"Payment Line Archive");
        ListOfTablesToMigrate.Add(Database::"Payment Line");
        ListOfTablesToMigrate.Add(Database::"Payment Post. Buffer");
        ListOfTablesToMigrate.Add(Database::"Payment Status");
        ListOfTablesToMigrate.Add(Database::"Payment Step Ledger");
        ListOfTablesToMigrate.Add(Database::"Payment Step");
        ListOfTablesToMigrate.Add(Database::"Shipment Invoiced");
        ListOfTablesToMigrate.Add(Database::"Unreal. CV Ledg. Entry Buffer");
    end;
}