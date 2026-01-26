codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(Database::"Data Exp. Primary Key Buffer");
        ListOfTablesToMigrate.Add(Database::"Data Export Buffer");
        ListOfTablesToMigrate.Add(Database::"Data Export Record Definition");
        ListOfTablesToMigrate.Add(Database::"Data Export Record Field");
        ListOfTablesToMigrate.Add(Database::"Data Export Record Source");
        ListOfTablesToMigrate.Add(Database::"Data Export Record Type");
        ListOfTablesToMigrate.Add(Database::"Data Export Setup");
        ListOfTablesToMigrate.Add(Database::"Data Export Table Relation");
        ListOfTablesToMigrate.Add(Database::"Data Export");
        ListOfTablesToMigrate.Add(Database::"Delivery Reminder Comment Line");
        ListOfTablesToMigrate.Add(Database::"Delivery Reminder Header");
        ListOfTablesToMigrate.Add(Database::"Delivery Reminder Ledger Entry");
        ListOfTablesToMigrate.Add(Database::"Delivery Reminder Level");
        ListOfTablesToMigrate.Add(Database::"Delivery Reminder Line");
        ListOfTablesToMigrate.Add(Database::"Delivery Reminder Term");
        ListOfTablesToMigrate.Add(Database::"Delivery Reminder Text");
        ListOfTablesToMigrate.Add(Database::"Issued Deliv. Reminder Header");
        ListOfTablesToMigrate.Add(Database::"Issued Deliv. Reminder Line");
        ListOfTablesToMigrate.Add(Database::"Key Buffer");
        ListOfTablesToMigrate.Add(Database::"Number Series Buffer");
        ListOfTablesToMigrate.Add(Database::"Place of Dispatcher");
        ListOfTablesToMigrate.Add(Database::"Place of Receiver");
        // obsoleted tables
#if not CLEANSCHEMA27
        ListOfTablesToMigrate.Add(5005361); // Database::"Expect. Phys. Inv. Track. Line"
        ListOfTablesToMigrate.Add(5005358); // Database::"Phys. Inventory Comment Line"
        ListOfTablesToMigrate.Add(5005350); // Database::"Phys. Inventory Order Header"
        ListOfTablesToMigrate.Add(5005351); // Database::"Phys. Inventory Order Line"
        ListOfTablesToMigrate.Add(5005363); // Database::"Phys. Invt. Diff. List Buffer"
        ListOfTablesToMigrate.Add(5005352); // Database::"Phys. Invt. Recording Header"
        ListOfTablesToMigrate.Add(5005353); // Database::"Phys. Invt. Recording Line"
        ListOfTablesToMigrate.Add(5005360); // Database::"Phys. Invt. Tracking Buffer"
        ListOfTablesToMigrate.Add(5005362); // Database::"Post. Exp. Ph. In. Track. Line"
        ListOfTablesToMigrate.Add(5005354); // Database::"Post. Phys. Invt. Order Header"
        ListOfTablesToMigrate.Add(5005355); // Database::"Posted Phys. Invt. Order Line"
        ListOfTablesToMigrate.Add(5005356); // Database::"Posted Phys. Invt. Rec. Header"
        ListOfTablesToMigrate.Add(5005357); // Database::"Posted Phys. Invt. Rec. Line"
        ListOfTablesToMigrate.Add(5005359); // Database::"Posted Phys. Invt. Track. Line"
#endif
#if not CLEANSCHEMA28
        ListOfTablesToMigrate.Add(26100); // Database::"DACH Report Selections"
#endif
    end;
}