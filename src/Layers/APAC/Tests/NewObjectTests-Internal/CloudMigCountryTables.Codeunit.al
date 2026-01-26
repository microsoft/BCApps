codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(Database::"BAS Calc. Sheet Entry");
        ListOfTablesToMigrate.Add(Database::"Address Buffer");
        ListOfTablesToMigrate.Add(Database::"Address ID");
        ListOfTablesToMigrate.Add(Database::"BAS Business Unit");
        ListOfTablesToMigrate.Add(Database::"BAS Calculation Sheet");
        ListOfTablesToMigrate.Add(Database::"BAS Comment Line");
        ListOfTablesToMigrate.Add(Database::"BAS Setup Name");
        ListOfTablesToMigrate.Add(Database::"BAS Setup");
        ListOfTablesToMigrate.Add(Database::"BAS XML Field ID Setup");
        ListOfTablesToMigrate.Add(Database::"BAS XML Field ID");
        ListOfTablesToMigrate.Add(Database::"BAS XML Field Setup Name");
        ListOfTablesToMigrate.Add(Database::"County");
        ListOfTablesToMigrate.Add(Database::"EFT Register");
        ListOfTablesToMigrate.Add(Database::"GST Purchase Entry");
        ListOfTablesToMigrate.Add(Database::"GST Sales Entry");
        ListOfTablesToMigrate.Add(Database::"Post Dated Check Line");
        ListOfTablesToMigrate.Add(Database::"Purch. Tax Cr. Memo Hdr.");
        ListOfTablesToMigrate.Add(Database::"Purch. Tax Cr. Memo Line");
        ListOfTablesToMigrate.Add(Database::"Purch. Tax Inv. Header");
        ListOfTablesToMigrate.Add(Database::"Purch. Tax Inv. Line");
        ListOfTablesToMigrate.Add(Database::"Sales Tax Cr.Memo Header");
        ListOfTablesToMigrate.Add(Database::"Sales Tax Cr.Memo Line");
        ListOfTablesToMigrate.Add(Database::"Sales Tax Invoice Header");
        ListOfTablesToMigrate.Add(Database::"Sales Tax Invoice Line");
        ListOfTablesToMigrate.Add(Database::"Tax Document Buffer Build");
        ListOfTablesToMigrate.Add(Database::"Tax Document Buffer");
        ListOfTablesToMigrate.Add(Database::"Tax Posting Buffer");
        ListOfTablesToMigrate.Add(Database::"Temp WHT Entry - EFiling");
        ListOfTablesToMigrate.Add(Database::"Temp WHT Entry");
        ListOfTablesToMigrate.Add(Database::"WHT Business Posting Group");
        ListOfTablesToMigrate.Add(Database::"WHT Certificate Buffer");
        ListOfTablesToMigrate.Add(Database::"WHT Entry");
        ListOfTablesToMigrate.Add(Database::"WHT Posting Setup");
        ListOfTablesToMigrate.Add(Database::"WHT Product Posting Group");
        ListOfTablesToMigrate.Add(Database::"WHT Revenue Types");
    end;
}