codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(Database::"340 Declaration Line");
        ListOfTablesToMigrate.Add(Database::"Acc. Schedule Buffer");
        ListOfTablesToMigrate.Add(Database::"AEAT Transference Format XML");
        ListOfTablesToMigrate.Add(Database::"AEAT Transference Format");
        ListOfTablesToMigrate.Add(Database::"BG/PO Comment Line");
        ListOfTablesToMigrate.Add(Database::"BG/PO Post. Buffer");
        ListOfTablesToMigrate.Add(Database::"Bill Group");
        ListOfTablesToMigrate.Add(Database::"Cartera Doc.");
        ListOfTablesToMigrate.Add(Database::"Cartera Report Selections");
        ListOfTablesToMigrate.Add(Database::"Cartera Setup");
        ListOfTablesToMigrate.Add(Database::"Category Code");
        ListOfTablesToMigrate.Add(Database::"Closed Bill Group");
        ListOfTablesToMigrate.Add(Database::"Closed Cartera Doc.");
        ListOfTablesToMigrate.Add(Database::"Closed Payment Order");
        ListOfTablesToMigrate.Add(Database::"Customer Cash Buffer");
        ListOfTablesToMigrate.Add(Database::"Customer Rating");
        ListOfTablesToMigrate.Add(Database::"Customer/Vendor Warning 349");
        ListOfTablesToMigrate.Add(Database::"Doc. Post. Buffer");
        ListOfTablesToMigrate.Add(Database::"Fee Range");
#if not CLEANSCHEMA28
        ListOfTablesToMigrate.Add(10720); //Database::"G/L Accounts Equivalence Tool"
        ListOfTablesToMigrate.Add(10721); //Database::"Historic G/L Account"
        ListOfTablesToMigrate.Add(10722); //Database::"New G/L Account"
        ListOfTablesToMigrate.Add(10723); //Database::"G/L Acc. Equiv. Tool Setup"
        ListOfTablesToMigrate.Add(10724); //Database::"History of Equivalences COA"
        ListOfTablesToMigrate.Add(10725); //Database::"Hist. G/L Account (An. View)"
#endif
        ListOfTablesToMigrate.Add(Database::"G/L Account Buffer");
        ListOfTablesToMigrate.Add(Database::"Gen. Prod. Post. Group Buffer");
        ListOfTablesToMigrate.Add(Database::"Inc. Stmt. Clos. Buffer");
        ListOfTablesToMigrate.Add(Database::"Installment");
        ListOfTablesToMigrate.Add(Database::"No Taxable Entry");
        ListOfTablesToMigrate.Add(Database::"Non-Payment Period");
        ListOfTablesToMigrate.Add(Database::"Operation Code");
        ListOfTablesToMigrate.Add(Database::"Operation Fee");
        ListOfTablesToMigrate.Add(Database::"Payment Day");
        ListOfTablesToMigrate.Add(Database::"Payment Order");
        ListOfTablesToMigrate.Add(Database::"Posted Bill Group");
        ListOfTablesToMigrate.Add(Database::"Posted Cartera Doc.");
        ListOfTablesToMigrate.Add(Database::"Posted Payment Order");
        ListOfTablesToMigrate.Add(Database::"Sales/Purch. Book VAT Buffer");
        ListOfTablesToMigrate.Add(Database::"Selected G/L Accounts");
        ListOfTablesToMigrate.Add(Database::"Selected Gen. Prod. Post. 340");
        ListOfTablesToMigrate.Add(Database::"Selected Gen. Prod. Post. Gr.");
        ListOfTablesToMigrate.Add(Database::"Selected Rev. Charge Grp. 340");
        ListOfTablesToMigrate.Add(Database::"SII Doc. Upload State");
        ListOfTablesToMigrate.Add(Database::"SII History");
        ListOfTablesToMigrate.Add(Database::"SII Missing Entries State");
        ListOfTablesToMigrate.Add(Database::"SII Purch. Doc. Scheme Code");
        ListOfTablesToMigrate.Add(Database::"SII Sales Document Scheme Code");
        ListOfTablesToMigrate.Add(Database::"SII Session");
        ListOfTablesToMigrate.Add(Database::"SII Setup");
        ListOfTablesToMigrate.Add(Database::"Statistical Code");
        ListOfTablesToMigrate.Add(Database::"Suffix");
        ListOfTablesToMigrate.Add(Database::"Test 340 Declaration Line Buf.");
        ListOfTablesToMigrate.Add(Database::"Test 347 Declaration Parameter");
    end;
}