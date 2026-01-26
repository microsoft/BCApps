// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

table 12105 "Withhold Code Line"
{
    Caption = 'Withhold Code Line';
    DrillDownPageID = "Withhold Code Lines";
    LookupPageID = "Withhold Code Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Withhold Code"; Code[20])
        {
            Caption = 'Withhold Code';
            TableRelation = "Withhold Code".Code;
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;
        }
        field(20; "Withholding Tax %"; Decimal)
        {
            Caption = 'Withholding Tax %';
            DecimalPlaces = 0 : 3;
            MaxValue = 100;
            MinValue = 0;
        }
        field(21; "Taxable Base %"; Decimal)
        {
            Caption = 'Taxable Base %';
            DecimalPlaces = 0 : 3;
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Withhold Code", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

