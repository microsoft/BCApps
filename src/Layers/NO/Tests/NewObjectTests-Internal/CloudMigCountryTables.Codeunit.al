codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(160801); // Database::"Acc. Schedules Conversion"
        ListOfTablesToMigrate.Add(160802); // Database::"Analysis Conversion"
        ListOfTablesToMigrate.Add(Database::"E-Invoice Export Header");
        ListOfTablesToMigrate.Add(Database::"E-Invoice Export Line");
        ListOfTablesToMigrate.Add(Database::"E-Invoice Transfer File");
        ListOfTablesToMigrate.Add(Database::"Gen. Jnl. Line Reg. Rep. Code");
        ListOfTablesToMigrate.Add(160800); // Database::"GL Accounts Conversion"
        ListOfTablesToMigrate.Add(Database::"OCR Setup");
        ListOfTablesToMigrate.Add(Database::"Payment Order Data");
        ListOfTablesToMigrate.Add(Database::"Payment Type Code Abroad");
        ListOfTablesToMigrate.Add(Database::"Recurring Group");
        ListOfTablesToMigrate.Add(Database::"Recurring Post");
        ListOfTablesToMigrate.Add(Database::"Regulatory Reporting Code");
        ListOfTablesToMigrate.Add(Database::"Remittance Account");
        ListOfTablesToMigrate.Add(Database::"Remittance Agreement");
        ListOfTablesToMigrate.Add(Database::"Remittance Payment Order");
        ListOfTablesToMigrate.Add(Database::"Return Error");
        ListOfTablesToMigrate.Add(Database::"Return File Setup");
        ListOfTablesToMigrate.Add(Database::"Return File");
        ListOfTablesToMigrate.Add(Database::"Settled VAT Period");
        ListOfTablesToMigrate.Add(Database::"VAT Reporting Code");
        ListOfTablesToMigrate.Add(Database::"VAT Note");
        ListOfTablesToMigrate.Add(Database::"VAT Period");
        ListOfTablesToMigrate.Add(Database::"VAT Specification");
        ListOfTablesToMigrate.Add(Database::"Waiting Journal");
    end;
}