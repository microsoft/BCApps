codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
#if not CLEAN29
#pragma warning disable AL0432
        ListOfTablesToMigrate.Add(Database::"Depr. Diff. Posting Buffer");
#pragma warning restore AL0432
#endif
        ListOfTablesToMigrate.Add(Database::"Foreign Payment Types");
        ListOfTablesToMigrate.Add(Database::"Ref. Payment - Exported Buffer");
        ListOfTablesToMigrate.Add(Database::"Ref. Payment - Exported");
        ListOfTablesToMigrate.Add(Database::"Ref. Payment - Imported");
        ListOfTablesToMigrate.Add(Database::"Reference File Setup");
    end;
}