codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(Database::"Depr. Diff. Posting Buffer");
        ListOfTablesToMigrate.Add(Database::"Foreign Payment Types");
        ListOfTablesToMigrate.Add(Database::"Ref. Payment - Exported Buffer");
        ListOfTablesToMigrate.Add(Database::"Ref. Payment - Exported");
        ListOfTablesToMigrate.Add(Database::"Ref. Payment - Imported");
        ListOfTablesToMigrate.Add(Database::"Reference File Setup");
    end;
}