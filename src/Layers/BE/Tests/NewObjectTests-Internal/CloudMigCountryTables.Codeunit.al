codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(Database::"CODA Statement Line");
        ListOfTablesToMigrate.Add(Database::"CODA Statement Source Line");
        ListOfTablesToMigrate.Add(Database::"CODA Statement");
        ListOfTablesToMigrate.Add(Database::"Domiciliation Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Domiciliation Journal Line");
        ListOfTablesToMigrate.Add(Database::"Domiciliation Journal Template");
        ListOfTablesToMigrate.Add(Database::"Electronic Banking Setup");
        ListOfTablesToMigrate.Add(Database::"Export Check Error Log");
        ListOfTablesToMigrate.Add(Database::"Export Protocol");
        ListOfTablesToMigrate.Add(Database::"G/L Entry Application Buffer");
        ListOfTablesToMigrate.Add(Database::"IBLC/BLWI Transaction Code");
        ListOfTablesToMigrate.Add(Database::"Manual VAT Correction");
        ListOfTablesToMigrate.Add(Database::"Paym. Journal Batch");
        ListOfTablesToMigrate.Add(Database::"Payment Journal Line");
        ListOfTablesToMigrate.Add(Database::"Payment Journal Template");
        ListOfTablesToMigrate.Add(Database::"Representative");
        ListOfTablesToMigrate.Add(Database::"Transaction Coding");
        ListOfTablesToMigrate.Add(Database::"VAT Summary Buffer");
        ListOfTablesToMigrate.Add(Database::"VAT VIES Correction");
    end;
}