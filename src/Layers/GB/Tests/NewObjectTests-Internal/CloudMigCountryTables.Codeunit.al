codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
#if not CLEANSCHEMA28
        ListOfTablesToMigrate.Add(10533); // Database::"MTD-Liability"
        ListOfTablesToMigrate.Add(10534); // Database::"MTD-Payment"
        ListOfTablesToMigrate.Add(10535); // Database::"MTD-Return Details"
        ListOfTablesToMigrate.Add(10536); // Database::"MTD-Missing Fraud Prev. Hdr"
        ListOfTablesToMigrate.Add(10537); // Database::"MTD-Default Fraud Prev. Hdr"
        ListOfTablesToMigrate.Add(10538); // Database::"MTD-Session Fraud Prev. Hdr"
#endif
#if not CLEANSCHEMA30
        ListOfTablesToMigrate.Add(10524); // Database::"GovTalk Message Parts"
        ListOfTablesToMigrate.Add(10523); // Database::"GovTalk Setup"
        ListOfTablesToMigrate.Add(10520); // Database::"GovTalkMessage"
#endif
#if not CLEANSCHEMA31
        ListOfTablesToMigrate.Add(10550); // Database::"BACS Ledger Entry"
        ListOfTablesToMigrate.Add(10551); // Database::"BACS Register"
        ListOfTablesToMigrate.Add(10555); // Database::"Fin. Charge Interest Rate"
        ListOfTablesToMigrate.Add(10501); // Database::"Postcode Notification Memory"
        ListOfTablesToMigrate.Add(10560); // Database::"Accounting Period GB"
#endif
    end;
}