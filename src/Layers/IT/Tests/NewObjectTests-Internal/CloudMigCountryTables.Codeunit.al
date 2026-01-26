codeunit 135161 "Cloud Mig Country Tables"
{
    procedure GetTablesThatShouldBeCloudMigrated(var ListOfTablesToMigrate: List of [Integer])
    begin
        ListOfTablesToMigrate.Add(Database::"ABI/CAB Codes");
        ListOfTablesToMigrate.Add(Database::"Activity Code");
        ListOfTablesToMigrate.Add(Database::"Appointment Code");
        ListOfTablesToMigrate.Add(Database::"Before Start Item Cost");
        ListOfTablesToMigrate.Add(Database::"Bill Posting Group");
        ListOfTablesToMigrate.Add(Database::"Bill");
        ListOfTablesToMigrate.Add(Database::"Blacklist Comm. Amount");
        ListOfTablesToMigrate.Add(Database::"Check Fiscal Code Setup");
        ListOfTablesToMigrate.Add(Database::"Company Officials");
        ListOfTablesToMigrate.Add(Database::"Company Types");
        ListOfTablesToMigrate.Add(Database::"Compress Depreciation");
        ListOfTablesToMigrate.Add(Database::"Computed Contribution");
        ListOfTablesToMigrate.Add(Database::"Computed Withholding Tax");
        ListOfTablesToMigrate.Add(Database::"Contribution Bracket Line");
        ListOfTablesToMigrate.Add(Database::"Contribution Bracket");
        ListOfTablesToMigrate.Add(Database::"Contribution Code Line");
        ListOfTablesToMigrate.Add(Database::"Contribution Code");
        ListOfTablesToMigrate.Add(Database::"Contribution Payment");
        ListOfTablesToMigrate.Add(Database::"Contributions");
        ListOfTablesToMigrate.Add(Database::"Customer Bill Header");
        ListOfTablesToMigrate.Add(Database::"Customer Bill Line");
        ListOfTablesToMigrate.Add(Database::"Customs Authority Vendor");
        ListOfTablesToMigrate.Add(Database::"Customs Office");
        ListOfTablesToMigrate.Add(Database::"Deferring Due Dates");
        ListOfTablesToMigrate.Add(Database::"Document Relation");
        ListOfTablesToMigrate.Add(Database::"Fattura Code");
        ListOfTablesToMigrate.Add(Database::"Fattura Document Type");
        ListOfTablesToMigrate.Add(Database::"Fattura Header");
        ListOfTablesToMigrate.Add(Database::"Fattura Line");
        ListOfTablesToMigrate.Add(Database::"Fattura Project Info");
        ListOfTablesToMigrate.Add(Database::"Fattura Setup");
        ListOfTablesToMigrate.Add(Database::"Fixed Due Dates");
        ListOfTablesToMigrate.Add(Database::"GL Book Entry");
        ListOfTablesToMigrate.Add(Database::"Goods Appearance");
        ListOfTablesToMigrate.Add(Database::"Incl. in VAT Report Error Log");
        ListOfTablesToMigrate.Add(Database::"Interest on Arrears");
        ListOfTablesToMigrate.Add(Database::"Issued Customer Bill Header");
        ListOfTablesToMigrate.Add(Database::"Issued Customer Bill Line");
        ListOfTablesToMigrate.Add(Database::"Item Cost History");
        ListOfTablesToMigrate.Add(Database::"Item Costing Setup");
        ListOfTablesToMigrate.Add(Database::"Lifo Band");
        ListOfTablesToMigrate.Add(Database::"Lifo Category");
        ListOfTablesToMigrate.Add(Database::"Payment Lines");
        ListOfTablesToMigrate.Add(Database::"Periodic VAT Settlement Entry");
#if not CLEANSCHEMA30
        ListOfTablesToMigrate.Add(12135); //Database::"Periodic Settlement VAT Entry"
#endif
        ListOfTablesToMigrate.Add(Database::"Posted Payment Lines");
        ListOfTablesToMigrate.Add(Database::"Posted Vendor Bill Header");
        ListOfTablesToMigrate.Add(Database::"Posted Vendor Bill Line");
        ListOfTablesToMigrate.Add(Database::"Purch. Withh. Contribution");
        ListOfTablesToMigrate.Add(Database::"Reprint Info Fiscal Reports");
        ListOfTablesToMigrate.Add(Database::"Service Tariff Number");
        ListOfTablesToMigrate.Add(Database::"Spesometro Appointment");
        ListOfTablesToMigrate.Add(Database::"Split VAT Test");
#if not CLEANSCHEMA30
        ListOfTablesToMigrate.Add(12152); // Database::"Subcontractor Prices")
#endif
        ListOfTablesToMigrate.Add(Database::"Tmp Withholding Contribution");
        ListOfTablesToMigrate.Add(Database::"Transport Reason Code");
        ListOfTablesToMigrate.Add(Database::"VAT Book Entry");
        ListOfTablesToMigrate.Add(Database::"VAT Exemption");
        ListOfTablesToMigrate.Add(Database::"VAT Identifier");
        ListOfTablesToMigrate.Add(Database::"VAT Plafond Period");
        ListOfTablesToMigrate.Add(Database::"VAT Register - Buffer");
        ListOfTablesToMigrate.Add(Database::"VAT Register");
        ListOfTablesToMigrate.Add(Database::"VAT Transaction Nature");
        ListOfTablesToMigrate.Add(Database::"VAT Transaction Report Amount");
        ListOfTablesToMigrate.Add(Database::"Vendor Bill Header");
        ListOfTablesToMigrate.Add(Database::"Vendor Bill Line");
        ListOfTablesToMigrate.Add(Database::"Vendor Bill Withholding Tax");
        ListOfTablesToMigrate.Add(Database::"Withhold Code Line");
        ListOfTablesToMigrate.Add(Database::"Withhold Code");
        ListOfTablesToMigrate.Add(Database::"Withholding Exceptional Event");
        ListOfTablesToMigrate.Add(Database::"Withholding Tax Line");
        ListOfTablesToMigrate.Add(Database::"Withholding Tax Payment");
        ListOfTablesToMigrate.Add(Database::"Withholding Tax");
    end;
}