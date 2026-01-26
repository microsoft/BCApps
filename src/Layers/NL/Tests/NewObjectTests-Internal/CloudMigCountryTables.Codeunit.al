codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(Database::"Audit File Buffer");
        ListOfTablesToMigrate.Add(Database::"CBG Statement Line Add. Info.");
        ListOfTablesToMigrate.Add(Database::"CBG Statement Line");
        ListOfTablesToMigrate.Add(Database::"CBG Statement");
        ListOfTablesToMigrate.Add(Database::"Detail Line");
        ListOfTablesToMigrate.Add(Database::"Elec. Tax Decl. Error Log");
        ListOfTablesToMigrate.Add(Database::"Elec. Tax Decl. Response Msg.");
        ListOfTablesToMigrate.Add(Database::"Elec. Tax Decl. VAT Category");
        ListOfTablesToMigrate.Add(Database::"Elec. Tax Declaration Header");
        ListOfTablesToMigrate.Add(Database::"Elec. Tax Declaration Line");
        ListOfTablesToMigrate.Add(Database::"Elec. Tax Declaration Setup");
        ListOfTablesToMigrate.Add(Database::"Export Protocol");
        ListOfTablesToMigrate.Add(Database::"Freely Transferable Maximum");
        ListOfTablesToMigrate.Add(Database::"G/L Entry Application Buffer");
        ListOfTablesToMigrate.Add(Database::"Import Protocol");
        ListOfTablesToMigrate.Add(Database::"Payment History Export Buffer");
        ListOfTablesToMigrate.Add(Database::"Payment History Line");
        ListOfTablesToMigrate.Add(Database::"Payment History");
        ListOfTablesToMigrate.Add(Database::"Post Code Range");
        ListOfTablesToMigrate.Add(Database::"Post Code Update Log Entry");
        ListOfTablesToMigrate.Add(Database::"Proposal Line");
        ListOfTablesToMigrate.Add(Database::"Reconciliation Buffer");
        ListOfTablesToMigrate.Add(Database::"Reporting ICP");
        ListOfTablesToMigrate.Add(Database::"SEPA CAMT File Parameters");
        ListOfTablesToMigrate.Add(Database::"Transaction Mode");
    end;
}