// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Projects.Project.Journal;
using Microsoft.Utilities;

table 5933 "Service Order Posting Buffer"
{
    Caption = 'Service Order Posting Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Entry Type"; Enum "Job Journal Line Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Posting Group Type"; Option)
        {
            Caption = 'Posting Group Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Resource,Item,Service Cost,Service Contract';
            OptionMembers = " ",Resource,Item,"Service Cost","Service Contract";
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        field(6; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(7; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(8; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        field(9; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;
        }
        field(11; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            DataClassification = SystemMetadata;
            TableRelation = "Work Type";
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(14; "Total Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Cost';
            DataClassification = SystemMetadata;
        }
        field(15; "Total Price"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Price';
            DataClassification = SystemMetadata;
        }
        field(16; "Appl.-to Service Entry"; Integer)
        {
            Caption = 'Appl.-to Service Entry';
            DataClassification = SystemMetadata;
        }
        field(17; "Service Contract No."; Code[20])
        {
            Caption = 'Service Contract No.';
            DataClassification = SystemMetadata;
        }
        field(18; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            DataClassification = SystemMetadata;
        }
        field(21; "Qty. to Invoice"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Qty. to Invoice';
            DataClassification = SystemMetadata;
        }
        field(22; "Location Code"; Code[20])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
        }
        field(23; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(24; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "Service Order No.", "Entry Type", "Posting Group Type", "No.", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Global Dimension 1 Code", "Global Dimension 2 Code", "Unit of Measure Code", "Service Item No.", "Location Code", "Appl.-to Service Entry")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

