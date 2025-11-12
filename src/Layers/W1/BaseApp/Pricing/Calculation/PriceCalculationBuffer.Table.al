// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;

table 7007 "Price Calculation Buffer"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            DataClassification = CustomerContent;
        }
        field(3; "Cost Calculation Method"; Enum "Price Calculation Method")
        {
            DataClassification = CustomerContent;
        }
        field(4; "Asset Type"; enum "Price Asset Type")
        {
            DataClassification = CustomerContent;
        }
        field(5; "Asset No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(6; "Variant Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(7; "Item Disc. Group"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(8; "Location Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(9; "Work Type Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(11; "Currency Factor"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(12; "Document Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(13; "Prices Including Tax"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(14; "Tax %"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(15; "VAT Calculation Type"; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(16; "VAT Bus. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(17; "VAT Prod. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(18; Quantity; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(19; "Unit of Measure Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(20; "Qty. per Unit of Measure"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(21; "Line Discount %"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(22; "Allow Line Disc."; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(23; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(24; "Unit Price"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(25; "Price Type"; Enum "Price Type")
        {
            DataClassification = CustomerContent;
        }
        field(26; "Is SKU"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(27; "Calculation in LCY"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}