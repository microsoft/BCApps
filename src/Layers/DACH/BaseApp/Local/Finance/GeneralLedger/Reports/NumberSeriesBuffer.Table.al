// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

table 11016 "Number Series Buffer"
{
    Caption = 'Number Series Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(4; "Table Name"; Text[30])
        {
            Caption = 'Table Name';
        }
        field(5; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
        }
        field(6; "Field Value"; Text[30])
        {
            Caption = 'Field Value';
        }
        field(7; Checked; Boolean)
        {
            Caption = 'Checked';
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

