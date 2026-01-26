// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

table 12107 "Contribution Code Line"
{
    Caption = 'Contribution Code Line';
    DrillDownPageID = "Contribution Code Lines";
    LookupPageID = "Contribution Code Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = "Contribution Code".Code;
        }
        field(10; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;
        }
        field(20; "Social Security Bracket Code"; Code[10])
        {
            Caption = 'Social Security Bracket Code';
            NotBlank = true;
            TableRelation = "Contribution Bracket" where("Contribution Type" = field("Contribution Type"));
        }
        field(21; "Social Security %"; Decimal)
        {
            Caption = 'Social Security %';
            DecimalPlaces = 0 : 4;
            MaxValue = 100;
            MinValue = 0;
        }
        field(22; "Free-Lance Amount %"; Decimal)
        {
            Caption = 'Free-Lance Amount %';
            DecimalPlaces = 0 : 4;
            MaxValue = 100;
            MinValue = 0;
        }
        field(23; "Contribution Type"; Option)
        {
            Caption = 'Contribution Type';
            OptionCaption = 'INPS,INAIL';
            OptionMembers = INPS,INAIL;
        }
    }

    keys
    {
        key(Key1; "Code", "Starting Date", "Contribution Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

