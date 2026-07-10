// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Setup / Configuration phase migrators. Each value implements the shared
/// "BC14 Migrator" interface. Execution order within the phase is determined by the
/// order in which migrators are added to the phase list (see PopulateSetupMigrators
/// in codeunit "BC14 Migration Runner"), not by the enum value.
/// </summary>
enum 46886 "BC14 Setup Migrator" implements "BC14 Migrator"
{
    Extensible = true;

    value(0; "Dimension")
    {
        Caption = 'Dimension';
        Implementation = "BC14 Migrator" = "BC14 Dimension Migrator";
    }
    value(1; "Dimension Value")
    {
        Caption = 'Dimension Value';
        Implementation = "BC14 Migrator" = "BC14 Dim. Value Migrator";
    }
    value(2; "Payment Terms")
    {
        Caption = 'Payment Terms';
        Implementation = "BC14 Migrator" = "BC14 Payment Terms Migrator";
    }
    value(3; "Payment Method")
    {
        Caption = 'Payment Method';
        Implementation = "BC14 Migrator" = "BC14 Payment Method Migrator";
    }
    value(4; "Currency")
    {
        Caption = 'Currency';
        Implementation = "BC14 Migrator" = "BC14 Currency Migrator";
    }
    value(5; "Currency Exchange Rate")
    {
        Caption = 'Currency Exchange Rate';
        Implementation = "BC14 Migrator" = "BC14 Curr. Exch. Rate Migrator";
    }
    value(6; "Accounting Period")
    {
        Caption = 'Accounting Period';
        Implementation = "BC14 Migrator" = "BC14 Acct. Period Migrator";
    }
    value(7; "Inventory Posting Group")
    {
        Caption = 'Inventory Posting Group';
        Implementation = "BC14 Migrator" = "BC14 Inv. Post. Group Migrator";
    }
    value(8; "Country/Region")
    {
        Caption = 'Country/Region';
        Implementation = "BC14 Migrator" = "BC14 Country/Region Migrator";
    }
    value(9; "Post Code")
    {
        Caption = 'Post Code';
        Implementation = "BC14 Migrator" = "BC14 Post Code Migrator";
    }
    value(10; "Language")
    {
        Caption = 'Language';
        Implementation = "BC14 Migrator" = "BC14 Language Migrator";
    }
    value(11; "Unit of Measure")
    {
        Caption = 'Unit of Measure';
        Implementation = "BC14 Migrator" = "BC14 Unit of Measure Migrator";
    }
    value(12; "Customer Posting Group")
    {
        Caption = 'Customer Posting Group';
        Implementation = "BC14 Migrator" = "BC14 Cust. Post. Grp. Migrator";
    }
    value(13; "Vendor Posting Group")
    {
        Caption = 'Vendor Posting Group';
        Implementation = "BC14 Migrator" = "BC14 Vend. Post. Grp. Migrator";
    }
    value(14; "Gen. Bus. Posting Group")
    {
        Caption = 'Gen. Bus. Posting Group';
        Implementation = "BC14 Migrator" = "BC14 GenBus PG Migrator";
    }
    value(15; "Gen. Prod. Posting Group")
    {
        Caption = 'Gen. Prod. Posting Group';
        Implementation = "BC14 Migrator" = "BC14 GenProd PG Migrator";
    }
    value(16; "VAT Bus. Posting Group")
    {
        Caption = 'VAT Bus. Posting Group';
        Implementation = "BC14 Migrator" = "BC14 VATBus PG Migrator";
    }
    value(17; "VAT Prod. Posting Group")
    {
        Caption = 'VAT Prod. Posting Group';
        Implementation = "BC14 Migrator" = "BC14 VATProd PG Migrator";
    }
    value(18; "General Posting Setup")
    {
        Caption = 'General Posting Setup';
        Implementation = "BC14 Migrator" = "BC14 Gen. Post. Setup Migrator";
    }
    value(19; "VAT Posting Setup")
    {
        Caption = 'VAT Posting Setup';
        Implementation = "BC14 Migrator" = "BC14 VAT Post. Setup Migrator";
    }
    value(20; "Salesperson/Purchaser")
    {
        Caption = 'Salesperson/Purchaser';
        Implementation = "BC14 Migrator" = "BC14 Salesp./Purch. Migrator";
    }
    value(21; "Shipment Method")
    {
        Caption = 'Shipment Method';
        Implementation = "BC14 Migrator" = "BC14 Shipment Method Migrator";
    }
    value(22; "Territory")
    {
        Caption = 'Territory';
        Implementation = "BC14 Migrator" = "BC14 Territory Migrator";
    }
    value(23; "Item Category")
    {
        Caption = 'Item Category';
        Implementation = "BC14 Migrator" = "BC14 Item Category Migrator";
    }
    value(24; "Item Tracking Code")
    {
        Caption = 'Item Tracking Code';
        Implementation = "BC14 Migrator" = "BC14 Item Trk. Code Migrator";
    }
    value(25; "Tariff Number")
    {
        Caption = 'Tariff Number';
        Implementation = "BC14 Migrator" = "BC14 Tariff Number Migrator";
    }
    value(26; "Location")
    {
        Caption = 'Location';
        Implementation = "BC14 Migrator" = "BC14 Location Migrator";
    }
    value(27; "Reason Code")
    {
        Caption = 'Reason Code';
        Implementation = "BC14 Migrator" = "BC14 Reason Code Migrator";
    }
    value(28; "Source Code")
    {
        Caption = 'Source Code';
        Implementation = "BC14 Migrator" = "BC14 Source Code Migrator";
    }
    value(29; "Customer Price Group")
    {
        Caption = 'Customer Price Group';
        Implementation = "BC14 Migrator" = "BC14 Cust. Price Grp. Migrator";
    }
    value(30; "Customer Discount Group")
    {
        Caption = 'Customer Discount Group';
        Implementation = "BC14 Migrator" = "BC14 Cust. Disc. Grp. Migrator";
    }
    value(31; "Item Discount Group")
    {
        Caption = 'Item Discount Group';
        Implementation = "BC14 Migrator" = "BC14 Item Disc. Grp. Migrator";
    }
    value(32; "Finance Charge Terms")
    {
        Caption = 'Finance Charge Terms';
        Implementation = "BC14 Migrator" = "BC14 Fin. Chrg. Terms Migrator";
    }
    value(33; "Reminder Terms")
    {
        Caption = 'Reminder Terms';
        Implementation = "BC14 Migrator" = "BC14 Reminder Terms Migrator";
    }
    value(34; "Reminder Level")
    {
        Caption = 'Reminder Level';
        Implementation = "BC14 Migrator" = "BC14 Reminder Level Migrator";
    }
    value(35; "Reminder Text")
    {
        Caption = 'Reminder Text';
        Implementation = "BC14 Migrator" = "BC14 Reminder Text Migrator";
    }
    value(36; "No. Series")
    {
        Caption = 'No. Series';
        Implementation = "BC14 Migrator" = "BC14 No. Series Migrator";
    }
    value(37; "No. Series Line")
    {
        Caption = 'No. Series Line';
        Implementation = "BC14 Migrator" = "BC14 No. Series Line Migrator";
    }
    value(38; "Item Attribute")
    {
        Caption = 'Item Attribute';
        Implementation = "BC14 Migrator" = "BC14 Item Attribute Migrator";
    }
    value(39; "Item Attribute Value")
    {
        Caption = 'Item Attribute Value';
        Implementation = "BC14 Migrator" = "BC14 Item Attr. Value Migrator";
    }
}
