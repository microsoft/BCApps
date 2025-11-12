// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

table 7110 "Analysis Field Value"
{
    Caption = 'Analysis Field Value';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Row Ref. No."; Integer)
        {
            Caption = 'Row Ref. No.';
        }
        field(2; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(3; Value; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Value';
        }
        field(4; "Has Error"; Boolean)
        {
            Caption = 'Has Error';
        }
        field(5; "Period Error"; Boolean)
        {
            Caption = 'Period Error';
        }
        field(6; "Formula Error"; Boolean)
        {
            Caption = 'Formula Error';
        }
        field(7; "Cyclic Error"; Boolean)
        {
            Caption = 'Cyclic Error';
        }
    }

    keys
    {
        key(Key1; "Row Ref. No.", "Column No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

