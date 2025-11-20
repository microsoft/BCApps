// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

table 5646 "Depreciation Table Buffer"
{
    Caption = 'Depreciation Table Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "No. of Days in Period"; Integer)
        {
            Caption = 'No. of Days in Period';
            DataClassification = SystemMetadata;
        }
        field(3; "Period Depreciation %"; Decimal)
        {
            Caption = 'Period Depreciation %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 1 : 1;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

