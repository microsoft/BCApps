// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

table 5610 "Adv. Bonus Depreciation Setup"
{
    Caption = 'Advanced Bonus Depreciation Setup';
    DataClassification = CustomerContent;
    LookupPageID = "Adv. Bonus Depr. Setup";
    DrillDownPageID = "Adv. Bonus Depr. Setup";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the date when this bonus depreciation percentage becomes effective.';
            NotBlank = true;
        }
        field(3; "FA Class Code"; Code[10])
        {
            Caption = 'Fixed Asset Class';
            DataClassification = CustomerContent;
            TableRelation = "FA Class";
            ToolTip = 'Specifies the fixed asset class this bonus depreciation percentage applies to. If blank, it applies to all classes.';
        }
        field(4; "Bonus Depreciation %"; Decimal)
        {
            Caption = 'Bonus Depreciation Percentage';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            AutoFormatType = 0;
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies the percentage of bonus depreciation for the given effective date and asset class.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Effective Date", "FA Class Code")
        {
            Unique = true;
        }
    }
}
