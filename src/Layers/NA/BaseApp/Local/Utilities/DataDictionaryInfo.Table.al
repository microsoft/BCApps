// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

table 10040 "Data Dictionary Info"
{
    Caption = 'Data Dictionary Info';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Table,Field,Caption,Option,Relation,CalcFormula,Key,SumIndexField,KeyGroup,Permission';
            OptionMembers = "Table","Field",Caption,Option,Relation,CalcFormula,"Key",SumIndexField,KeyGroup,Permission;
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(4; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(5; "Data Type"; Code[20])
        {
            Caption = 'Data Type';
        }
        field(6; Length; Code[10])
        {
            Caption = 'Length';
        }
        field(7; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(8; Language; Code[10])
        {
            Caption = 'Language';
        }
        field(9; Value; Text[150])
        {
            Caption = 'Value';
        }
        field(10; Enabled; Text[10])
        {
            Caption = 'Enabled';
        }
        field(11; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(12; "Field Class"; Code[20])
        {
            Caption = 'Field Class';
        }
        field(13; "Key No."; Integer)
        {
            Caption = 'Key No.';
        }
        field(14; OnLookup; Boolean)
        {
            Caption = 'OnLookup';
        }
        field(15; OnValidate; Boolean)
        {
            Caption = 'OnValidate';
        }
        field(16; "Read Permission"; Boolean)
        {
            Caption = 'Read Permission';
        }
        field(17; "Insert Permission"; Boolean)
        {
            Caption = 'Insert Permission';
        }
        field(18; "Modify Permission"; Boolean)
        {
            Caption = 'Modify Permission';
        }
        field(19; "Delete Permission"; Boolean)
        {
            Caption = 'Delete Permission';
        }
        field(20; "Execute Permission"; Boolean)
        {
            Caption = 'Execute Permission';
        }
    }

    keys
    {
        key(Key1; "Table No.", "Field No.", Type, Language, "Key No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

