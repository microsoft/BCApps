// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

table 10240 "B10 Adjustment"
{
    Caption = 'B10 Adjustment';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Date; Date)
        {
            Caption = 'Date';
            NotBlank = true;
        }
        field(2; "Adjustment Amount"; Decimal)
        {
            Caption = 'Adjustment Amount';
            DecimalPlaces = 2 : 5;
        }
    }

    keys
    {
        key(Key1; Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

