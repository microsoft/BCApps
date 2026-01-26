codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(11202); // Database::"Inward Reg. Entry"
        ListOfTablesToMigrate.Add(11200); // Database::"Inward Reg. Header"
        ListOfTablesToMigrate.Add(11201); // Database::"Inward Reg. Line"
    end;
}