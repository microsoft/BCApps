// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

table 386 "Entry No. Amount Buffer"
{
    Caption = 'Entry No. Amount Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(3; Amount2; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount2';
            DataClassification = SystemMetadata;
        }
        field(4; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = SystemMetadata;
        }
        field(6; "End Date"; Date)
        {
            Caption = 'End Date';
            DataClassification = SystemMetadata;
        }
        field(7; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            DataClassification = SystemMetadata;
        }
        field(8; "Source Currency Amount"; Decimal)
        {
            Caption = 'Source Currency Amount';
            DataClassification = SystemMetadata;
        }
        field(9; "Source Currency VAT Amount"; Decimal)
        {
            Caption = 'Source Currency VAT Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Business Unit Code", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

