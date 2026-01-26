// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.Setup;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

table 1382 "Item Templ."
{
    Caption = 'Item Template';
    LookupPageID = "Item Templ. List";
    DrillDownPageID = "Item Templ. List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Base Unit of Measure"));
            end;
        }
        field(9; "Price Unit Conversion"; Integer)
        {
            Caption = 'Price Unit Conversion';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Price Unit Conversion"));
            end;
        }
        field(10; Type; Enum "Item Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                if (Type = Type::Service) or (Type = Type::"Non-Inventory") then
                    Validate("Inventory Posting Group", '');

                ValidateItemField(FieldNo(Type));
            end;
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Inventory Posting Group"));
            end;
        }
        field(12; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Shelf No."));
            end;
        }
        field(14; "Item Disc. Group"; Code[20])
        {
            Caption = 'Item Disc. Group';
            TableRelation = "Item Discount Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Item Disc. Group"));
            end;
        }
        field(15; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Allow Invoice Disc."));
            end;
        }
        field(16; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
            ToolTip = 'Specifies the statistics group.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Statistics Group"));
            end;
        }
        field(17; "Commission Group"; Integer)
        {
            Caption = 'Commission Group';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Commission Group"));
            end;
        }
        field(18; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Unit Price"));
            end;
        }
        field(19; "Price/Profit Calculation"; Enum "Item Price Profit Calculation")
        {
            Caption = 'Price/Profit Calculation';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Price/Profit Calculation"));
            end;
        }
        field(20; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Profit %"));
            end;
        }
        field(21; "Costing Method"; Enum "Costing Method")
        {
            Caption = 'Costing Method';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Costing Method"));
            end;
        }
        field(22; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Unit Cost"));
            end;
        }
        field(24; "Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Standard Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Standard Cost"));
            end;
        }
        field(28; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Indirect Cost %"));
            end;
        }
        field(31; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            ValidateTableRelation = true;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Vendor No."));
            end;
        }
        field(32; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Vendor Item No."));
            end;
        }
        field(33; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Lead Time Calculation"));
            end;
        }
        field(34; "Reorder Point"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reorder Point';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Reorder Point"));
            end;
        }
        field(35; "Maximum Inventory"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Inventory';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Maximum Inventory"));
            end;
        }
        field(36; "Reorder Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reorder Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Reorder Quantity"));
            end;
        }
        field(37; "Alternative Item No."; Code[20])
        {
            Caption = 'Alternative Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Alternative Item No."));
            end;
        }
        field(38; "Unit List Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit List Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Unit List Price"));
            end;
        }
        field(39; "Duty Due %"; Decimal)
        {
            Caption = 'Duty Due %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Duty Due %"));
            end;
        }
        field(40; "Duty Code"; Code[10])
        {
            Caption = 'Duty Code';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Duty Code"));
            end;
        }
        field(41; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Gross Weight"));
            end;
        }
        field(42; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Net Weight"));
            end;
        }
        field(43; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Units per Parcel"));
            end;
        }
        field(44; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Unit Volume"));
            end;
        }
        field(45; Durability; Code[10])
        {
            Caption = 'Durability';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(Durability));
            end;
        }
        field(46; "Freight Type"; Code[10])
        {
            Caption = 'Freight Type';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Freight Type"));
            end;
        }
        field(47; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            TableRelation = "Tariff Number";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Tariff No."));
            end;
        }
        field(48; "Duty Unit Conversion"; Decimal)
        {
            Caption = 'Duty Unit Conversion';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Duty Unit Conversion"));
            end;
        }
        field(49; "Country/Region Purchased Code"; Code[10])
        {
            Caption = 'Country/Region Purchased Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Country/Region Purchased Code"));
            end;
        }
        field(50; "Budget Quantity"; Decimal)
        {
            Caption = 'Budget Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Budget Quantity"));
            end;
        }
        field(51; "Budgeted Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Budgeted Amount';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Budgeted Amount"));
            end;
        }
        field(52; "Budget Profit"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Budget Profit';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Budget Profit"));
            end;
        }
        field(54; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(Blocked));
            end;
        }
        field(56; "Block Reason"; Text[250])
        {
            Caption = 'Block Reason';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Block Reason"));
            end;
        }
        field(87; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Price Includes VAT"));
            end;
        }
        field(90; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("VAT Bus. Posting Gr. (Price)"));
            end;
        }
        field(91; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Gen. Prod. Posting Group"));
            end;
        }
        field(95; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Country/Region of Origin Code"));
            end;
        }
        field(96; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Automatic Ext. Texts"));
            end;
        }
        field(97; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("No. Series"));
            end;
        }
        field(98; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Tax Group Code"));
            end;
        }
        field(99; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("VAT Prod. Posting Group"));
            end;
        }
        field(100; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Reserve';
            InitValue = Optional;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(Reserve));
            end;
        }
        field(105; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(106; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(120; "Stockout Warning"; Option)
        {
            Caption = 'Stockout Warning';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Stockout Warning"));
            end;
        }
        field(121; "Prevent Negative Inventory"; Option)
        {
            Caption = 'Prevent Negative Inventory';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Prevent Negative Inventory"));
            end;
        }
        field(122; "Variant Mandatory if Exists"; Option)
        {
            Caption = 'Variant Mandatory if Exists';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(910; "Assembly Policy"; Enum "Assembly Policy")
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assembly Policy';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Assembly Policy"));
            end;
        }
        field(1217; GTIN; Code[14])
        {
            Caption = 'GTIN';
            Numeric = true;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(GTIN));
            end;
        }
        field(1700; "Default Deferral Template Code"; Code[10])
        {
            Caption = 'Default Deferral Template Code';
            TableRelation = "Deferral Template"."Deferral Code";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Default Deferral Template Code"));
            end;
        }
        field(5401; "Lot Size"; Decimal)
        {
            Caption = 'Lot Size';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Lot Size"));
            end;
        }
        field(5402; "Serial Nos."; Code[20])
        {
            Caption = 'Serial Nos.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Serial Nos."));
            end;
        }
        field(5407; "Scrap %"; Decimal)
        {
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 2;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Scrap %"));
            end;
        }
        field(5408; "Rolled-up Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Material Non-Inventory Cost';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Rolled-up Mat. Non-Invt. Cost"));
            end;
        }
        field(5409; "Inventory Value Zero"; Boolean)
        {
            Caption = 'Inventory Value Zero';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Inventory Value Zero"));
            end;
        }
        field(5410; "Discrete Order Quantity"; Integer)
        {
            Caption = 'Discrete Order Quantity';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Discrete Order Quantity"));
            end;
        }
        field(5411; "Minimum Order Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Minimum Order Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Minimum Order Quantity"));
            end;
        }
        field(5412; "Maximum Order Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Order Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Maximum Order Quantity"));
            end;
        }
        field(5413; "Safety Stock Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Stock Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Safety Stock Quantity"));
            end;
        }
        field(5414; "Order Multiple"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Order Multiple';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Order Multiple"));
            end;
        }
        field(5415; "Safety Lead Time"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Lead Time';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Safety Lead Time"));
            end;
        }
        field(5417; "Flushing Method"; Enum Microsoft.Manufacturing.Setup."Flushing Method")
        {
            Caption = 'Flushing Method';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Flushing Method"));
            end;
        }
        field(5419; "Replenishment System"; Enum "Replenishment System")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Replenishment System';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Replenishment System"));
            end;
        }
        field(5422; "Rounding Precision"; Decimal)
        {
            Caption = 'Rounding Precision';
            DecimalPlaces = 0 : 5;
            InitValue = 1;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Rounding Precision"));
            end;
        }
        field(5428; "Time Bucket"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Time Bucket';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Time Bucket"));
            end;
        }
        field(5440; "Reordering Policy"; Enum "Reordering Policy")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reordering Policy';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Reordering Policy"));
            end;
        }
        field(5441; "Include Inventory"; Boolean)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Include Inventory';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Include Inventory"));
            end;
        }
        field(5442; "Manufacturing Policy"; Enum Microsoft.Manufacturing.Setup."Manufacturing Policy")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Manufacturing Policy';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Manufacturing Policy"));
            end;
        }
        field(5443; "Rescheduling Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Rescheduling Period';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Rescheduling Period"));
            end;
        }
        field(5444; "Lot Accumulation Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Lot Accumulation Period';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Lot Accumulation Period"));
            end;
        }
        field(5445; "Dampener Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Dampener Period';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Dampener Period"));
            end;
        }
        field(5446; "Dampener Quantity"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Dampener Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Dampener Quantity"));
            end;
        }
        field(5447; "Overflow Level"; Decimal)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Overflow Level';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Overflow Level"));
            end;
        }
        field(5701; "Manufacturer Code"; Code[10])
        {
            Caption = 'Manufacturer Code';
            TableRelation = Manufacturer;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Manufacturer Code"));
            end;
        }
        field(5702; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Item Category Code"));
            end;
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Purchasing Code"));
            end;
        }
        field(6502; "Expiration Calculation"; DateFormula)
        {
            Caption = 'Expiration Calculation';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Expiration Calculation"));
            end;
        }
        field(6500; "Item Tracking Code"; Code[10])
        {
            Caption = 'Item Tracking Code';
            TableRelation = "Item Tracking Code";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Item Tracking Code"));
            end;
        }
        field(6501; "Lot Nos."; Code[20])
        {
            Caption = 'Lot Nos.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Lot Nos."));
            end;
        }
        field(7301; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Special Equipment Code"));
            end;
        }
        field(7302; "Put-away Template Code"; Code[10])
        {
            Caption = 'Put-away Template Code';
            TableRelation = "Put-away Template Header";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Put-away Template Code"));
            end;
        }
        field(7300; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            TableRelation = "Warehouse Class";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Warehouse Class Code"));
            end;
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            TableRelation = "Phys. Invt. Counting Period";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Phys Invt Counting Period Code"));
            end;
        }
        field(7384; "Use Cross-Docking"; Boolean)
        {
            AccessByPermission = TableData "Bin Content" = R;
            Caption = 'Use Cross-Docking';
            InitValue = true;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Use Cross-Docking"));
            end;
        }
        field(8003; "Sales Blocked"; Boolean)
        {
            Caption = 'Sales Blocked';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Sales Blocked"));
            end;
        }
        field(8004; "Purchasing Blocked"; Boolean)
        {
            Caption = 'Purchasing Blocked';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Purchasing Blocked"));
            end;
        }
        field(8010; "Service Blocked"; Boolean)
        {
            Caption = 'Service Blocked';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Service Blocked"));
            end;
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Over-Receipt Code"));
            end;
        }
        field(99000757; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Overhead Rate';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Overhead Rate"));
            end;
        }
        field(99000773; "Order Tracking Policy"; Enum "Order Tracking Policy")
        {
            Caption = 'Order Tracking Policy';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Order Tracking Policy"));
            end;
        }
        field(99000875; Critical; Boolean)
        {
            Caption = 'Critical';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(Critical));
            end;
        }
        field(99008500; "Common Item No."; Code[20])
        {
            Caption = 'Common Item No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Common Item No."));
            end;
        }
#if not CLEANSCHEMA30
        field(10500; "Reverse Charge Applies"; Boolean)
        {
            Caption = 'Reverse Charge Applies';
            ObsoleteReason = 'Moved to Reverse Charge VAT GB app';
#if CLEAN27
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#endif

#if not CLEAN27
            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Reverse Charge Applies"));
            end;
#endif
        }
#endif
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
        key(CategoryKey; "Item Category Code")
        {
        }
    }

    trigger OnDelete()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", Database::"Item Templ.");
        DefaultDimension.SetRange("No.", Code);
        DefaultDimension.DeleteAll();
    end;

    trigger OnRename()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.RenameDefaultDim(Database::"Item Templ.", xRec.Code, Code);
    end;

    local procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(Database::"Item Templ.", Code, FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;

    procedure CopyFromTemplate(SourceItemTempl: Record "Item Templ.")
    begin
        CopyTemplate(SourceItemTempl);
        CopyDimensions(SourceItemTempl);
        OnAfterCopyFromTemplate(SourceItemTempl, Rec);
    end;

    local procedure CopyTemplate(SourceItemTempl: Record "Item Templ.")
    var
        SavedItemTempl: Record "Item Templ.";
    begin
        SavedItemTempl := Rec;
        TransferFields(SourceItemTempl, false);
        Code := SavedItemTempl.Code;
        Description := SavedItemTempl.Description;
        OnCopyTemplateOnBeforeModify(SourceItemTempl, SavedItemTempl, Rec);
        Modify();
    end;

    local procedure CopyDimensions(SourceItemTempl: Record "Item Templ.")
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        DestDefaultDimension.SetRange("Table ID", Database::"Item Templ.");
        DestDefaultDimension.SetRange("No.", Code);
        DestDefaultDimension.DeleteAll(true);

        SourceDefaultDimension.SetRange("Table ID", Database::"Item Templ.");
        SourceDefaultDimension.SetRange("No.", SourceItemTempl.Code);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::"Item Templ.");
                DestDefaultDimension.Validate("No.", Code);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if DestDefaultDimension.Insert(true) then;
            until SourceDefaultDimension.Next() = 0;
    end;

    procedure ValidateItemField(FieldId: Integer)
    var
        ItemRecordRef: RecordRef;
        ItemTemplRecordRef: RecordRef;
        ItemFieldRef: FieldRef;
        ItemTemplFieldRef: FieldRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateItemField(Rec, FieldId, IsHandled);
        if IsHandled then
            exit;

        ItemTemplRecordRef.GetTable(Rec);
        ItemRecordRef.Open(Database::Item, true);
        TransferFieldValues(ItemTemplRecordRef, ItemRecordRef, false);
        ItemRecordRef.Insert();

        ItemFieldRef := ItemRecordRef.Field(FieldId);
        ItemTemplFieldRef := ItemTemplRecordRef.Field(FieldId);
        ItemFieldRef.Validate(ItemTemplFieldRef.Value);

        TransferFieldValues(ItemTemplRecordRef, ItemRecordRef, true);

        ItemTemplRecordRef.SetTable(Rec);
        Modify();
    end;

    local procedure TransferFieldValues(var SrcRecRef: RecordRef; var DestRecRef: RecordRef; Reverse: Boolean)
    var
        SrcFieldRef: FieldRef;
        DestFieldRef: FieldRef;
        i: Integer;
        IsHandled: Boolean;
    begin
        for i := 3 to SrcRecRef.FieldCount do begin
            SrcFieldRef := SrcRecRef.FieldIndex(i);
            IsHandled := false;
            OnTransferFieldValuesOnBeforeTransferFieldValue(SrcFieldRef, DestFieldRef, Reverse, IsHandled);
            if not IsHandled then begin
                DestFieldRef := DestRecRef.Field(SrcFieldRef.Number);
                if not Reverse then
                    DestFieldRef.Value := SrcFieldRef.Value()
                else
                    SrcFieldRef.Value := DestFieldRef.Value();
            end;
        end;

        OnAfterTransferFieldValues(SrcRecRef, DestRecRef, Reverse);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTemplate(SourceItemTempl: Record "Item Templ."; var ItemTempl: Record "Item Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyTemplateOnBeforeModify(SourceItemTempl: Record "Item Templ."; SavedItemTempl: Record "Item Templ."; var ItemTempl: Record "Item Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemField(var ItemTempl: record "Item Templ."; FieldId: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldValues(var SrcRecRef: RecordRef; var DestRecRef: RecordRef; Reverse: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFieldValuesOnBeforeTransferFieldValue(var SrcFieldRef: FieldRef; var DestFieldRef: FieldRef; Reverse: Boolean; var IsHandled: Boolean)
    begin
    end;
}

