codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        // RU does not test for cloud migration
        Clear(ListOfTablesToMigrate);
    end;
}