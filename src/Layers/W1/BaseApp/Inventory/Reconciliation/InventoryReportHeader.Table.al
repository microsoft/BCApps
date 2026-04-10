// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reconciliation;

table 5845 "Inventory Report Header"
{
    Caption = 'Inventory Report Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(3; "Item Filter"; Code[20])
        {
            Caption = 'Item Filter';
            FieldClass = FlowFilter;
        }
        field(5; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
        }
        field(6; "Posting Date Filter"; Date)
        {
            Caption = 'Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(7; Calculated; Boolean)
        {
            Caption = 'Calculated';
        }
        field(9; "Line Option"; Option)
        {
            Caption = 'Line Option';
            OptionCaption = 'Balance Sheet,Income Statement';
            OptionMembers = "Balance Sheet","Income Statement";
        }
        field(10; "Column Option"; Option)
        {
            Caption = 'Column Option';
            OptionCaption = 'Balance Sheet,Income Statement';
            OptionMembers = "Balance Sheet","Income Statement";
        }
        field(11; "Show Warning"; Boolean)
        {
            Caption = 'Show Warning';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

