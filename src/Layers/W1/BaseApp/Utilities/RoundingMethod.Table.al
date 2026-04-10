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
            ToolTip = 'Specifies a code for the rounding method for item prices.';
            NotBlank = true;
        }
        field(2; "Minimum Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Minimum Amount';
            ToolTip = 'Specifies the minimum amount to round.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(3; "Amount Added Before"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount Added Before';
            ToolTip = 'Specifies an amount to add before it is rounded.';
            DecimalPlaces = 0 : 5;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies how to round.';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(5; Precision; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Precision';
            ToolTip = 'Specifies the size of the interval that you want between rounded amounts.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(6; "Amount Added After"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount Added After';
            ToolTip = 'Specifies an amount to add, after the amount has been rounded.';
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

