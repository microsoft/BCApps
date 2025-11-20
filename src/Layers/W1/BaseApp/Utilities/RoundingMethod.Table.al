// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

table 42 "Rounding Method"
{
    Caption = 'Rounding Method';
    LookupPageID = "Rounding Methods";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Minimum Amount"; Decimal)
        {
            Caption = 'Minimum Amount';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(3; "Amount Added Before"; Decimal)
        {
            Caption = 'Amount Added Before';
            DecimalPlaces = 0 : 5;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(5; Precision; Decimal)
        {
            Caption = 'Precision';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(6; "Amount Added After"; Decimal)
        {
            Caption = 'Amount Added After';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Code", "Minimum Amount")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

