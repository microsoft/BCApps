#if not CLEANSCHEMA25 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;

table 263 "Intrastat Jnl. Line"
{
    Caption = 'Intrastat Jnl. Line';
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Receipt,Shipment';
            OptionMembers = Receipt,Shipment;
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            NotBlank = true;
        }
        field(7; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
        }
        field(8; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(9; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(10; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
#if not CLEANSCHEMA29
#pragma warning disable AS0105        
        field(11; "Source Type"; Enum "Intrastat Source Type")
        {
            Caption = 'Source Type';
#if CLEAN26
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '26.0';
#endif
            ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
        }
#pragma warning restore AS0105
#endif
        field(12; "Source Entry No."; Integer)
        {
            Caption = 'Source Entry No.';
        }
        field(13; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 2 : 5;
        }
        field(14; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DecimalPlaces = 0 : 0;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 0;
        }
        field(16; "Cost Regulation %"; Decimal)
        {
            Caption = 'Cost Regulation %';
            DecimalPlaces = 2 : 2;
            MaxValue = 100;
            MinValue = -100;
        }
        field(17; "Indirect Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Indirect Cost';
            DecimalPlaces = 0 : 0;
        }
        field(18; "Statistical Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Statistical Value';
            DecimalPlaces = 0 : 0;
        }
        field(19; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(21; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(22; "Total Weight"; Decimal)
        {
            Caption = 'Total Weight';
            DecimalPlaces = 0 : 0;
            Editable = false;
        }
        field(23; "Supplementary Units"; Boolean)
        {
            Caption = 'Supplementary Units';
            Editable = false;
        }
        field(24; "Internal Ref. No."; Text[10])
        {
            Caption = 'Internal Ref. No.';
            Editable = false;
        }
        field(25; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            TableRelation = "Country/Region";
        }
        field(26; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(27; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(28; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(29; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(30; "Partner VAT ID"; Text[50])
        {
            Caption = 'Partner VAT ID';
        }
        field(31; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(32; Counterparty; Boolean)
        {
            Caption = 'Counterparty';
        }
        field(12100; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(12101; "Source Currency Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Source Currency Amount';
        }
        field(12102; "VAT Registration No."; Code[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(12103; "Corrective entry"; Boolean)
        {
            Caption = 'Corrective entry';
        }
        field(12104; "Group Code"; Code[10])
        {
            Caption = 'Group Code';
            Editable = false;
        }
        field(12105; "Statistics Period"; Code[10])
        {
            Caption = 'Statistics Period';
            Editable = true;
        }
        field(12115; "Reference Period"; Code[10])
        {
            Caption = 'Reference Period';
            Numeric = true;
        }
        field(12125; "Service Tariff No."; Code[10])
        {
            Caption = 'Service Tariff No.';
            TableRelation = "Service Tariff Number";
        }
        field(12178; "Payment Method"; Code[10])
        {
            Caption = 'Payment Method';
        }
        field(12179; "Custom Office No."; Code[6])
        {
            Caption = 'Custom Office No.';
            TableRelation = "Customs Office";
        }
        field(12180; "Corrected Intrastat Report No."; Code[10])
        {
            Caption = 'Corrected Intrastat Report No.';
        }
        field(12181; "Corrected Document No."; Code[20])
        {
            Caption = 'Corrected Document No.';
        }
        field(12182; "Country/Region of Payment Code"; Code[10])
        {
            Caption = 'Country/Region of Payment Code';
            TableRelation = "Country/Region";
        }
        field(12183; "Progressive No."; Code[5])
        {
            Caption = 'Progressive No.';
        }
        field(12185; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
#if not CLEAN26
        key(Key2; "Source Type", "Source Entry No.")
        {
        }
#endif
        key(Key4; "Internal Ref. No.")
        {
        }
        key(Key5; "Document No.")
        {
        }
        key(Key6; Type, "Country/Region Code", "Partner VAT ID", "Transaction Type", "Tariff No.", "Group Code", "Transport Method", "Transaction Specification", "Country/Region of Origin Code", "Area", "Corrective entry")
        {
        }
    }

    fieldgroups
    {
    }
}

 
#endif
