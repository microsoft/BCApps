// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

table 5641 "FA Buffer Projection"
{
    Caption = 'FA Buffer Projection';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
            DataClassification = SystemMetadata;
        }
        field(3; Depreciation; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Depreciation';
            DataClassification = SystemMetadata;
        }
        field(4; "Custom 1"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Custom 1';
            DataClassification = SystemMetadata;
        }
        field(5; "Code Name"; Code[20])
        {
            Caption = 'Code Name';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Code Name", "FA Posting Date", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

