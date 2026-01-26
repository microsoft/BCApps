codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.SetFilter(ID, '%1..%2|%3..%4', 11700, 11799, 31000, 31499); // range for CZ object
        TableMetadata.FindSet();
        repeat
            ListOfTablesToMigrate.Add(TableMetadata.ID);
        until TableMetadata.Next() = 0;
    end;
}