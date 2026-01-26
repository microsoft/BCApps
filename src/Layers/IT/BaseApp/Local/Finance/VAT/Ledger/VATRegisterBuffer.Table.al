// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.VAT.Setup;

table 12148 "VAT Register - Buffer"
{
    Caption = 'VAT Register - Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
            DataClassification = SystemMetadata;
        }
        field(2; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
            DataClassification = SystemMetadata;
        }
        field(3; "VAT Register Code"; Code[10])
        {
            Caption = 'VAT Register Code';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Register";
        }
        field(10; "Register Type"; Option)
        {
            Caption = 'Register Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Purchase,Sale';
            OptionMembers = Purchase,Sale;
        }
        field(11; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(12; "VAT Deductible %"; Decimal)
        {
            Caption = 'VAT Deductible %';
            DataClassification = SystemMetadata;
        }
        field(13; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
        }
        field(14; Base; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base';
            DataClassification = SystemMetadata;
        }
        field(15; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(16; "Nondeductible Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Nondeductible Base';
            DataClassification = SystemMetadata;
        }
        field(17; "Nondeductible Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Nondeductible Amount';
            DataClassification = SystemMetadata;
        }
        field(20; "Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unrealized Base';
            DataClassification = SystemMetadata;
        }
        field(21; "Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unrealized Amount';
            DataClassification = SystemMetadata;
        }
        field(22; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Identifier";
        }
    }

    keys
    {
        key(Key1; "Period Start Date", "Period End Date", "VAT Register Code", "VAT Identifier", "Register Type", "VAT Prod. Posting Group", "VAT Deductible %", "VAT %")
        {
            Clustered = true;
        }
        key(Key2; "Register Type", "VAT Prod. Posting Group", "VAT Identifier", "VAT %", "VAT Deductible %")
        {
        }
        key(Key3; "VAT Register Code")
        {
        }
    }

    fieldgroups
    {
    }
}

