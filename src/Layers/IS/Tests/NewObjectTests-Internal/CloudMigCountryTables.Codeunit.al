codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(14600); // Database::"IS IRS Groups"
        ListOfTablesToMigrate.Add(14601); // Database::"IS IRS Numbers");
        ListOfTablesToMigrate.Add(14602); //Database::"IS IRS Types");

        // obsoleted tables:
#if not CLEANSCHEMA27
        ListOfTablesToMigrate.Add(10901); // Database::"IRS Groups"
        ListOfTablesToMigrate.Add(10900); // Database::"IRS Numbers"
        ListOfTablesToMigrate.Add(10902); // Database::"IRS Types"
        ListOfTablesToMigrate.Add(10903); // Database::"IS Core App Setup"
#endif
    end;
}