namespace System.Visualization;

using System.Reflection;

table 9180 "Generic Chart Setup"
{
    Caption = 'Generic Chart Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(2; ID; Code[20])
        {
            Caption = 'ID';
            NotBlank = true;
        }
        field(3; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Table,Query';
            OptionMembers = " ","Table","Query";
        }
        field(10; Name; Text[50])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                Title := Name;
            end;
        }
        field(11; Title; Text[250])
        {
            Caption = 'Title';
        }
        field(12; "Filter Text"; Text[250])
        {
            Caption = 'Filter Text';
        }
        field(15; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Column,Point';
            OptionMembers = Column,Point;
        }
        field(16; "Source ID"; Integer)
        {
            Caption = 'Source ID';
        }
        field(17; "Object Name"; Text[30])
        {
            Caption = 'Object Name';
            Editable = false;
        }
        field(20; "X-Axis Field ID"; Integer)
        {
            Caption = 'X-Axis Field ID';
        }
        field(21; "X-Axis Field Name"; Text[80])
        {
            Caption = 'X-Axis Field Name';
        }
        field(22; "X-Axis Field Caption"; Text[250])
        {
            Caption = 'X-Axis Field Caption';
        }
        field(23; "X-Axis Title"; Text[250])
        {
            Caption = 'X-Axis Title';
        }
        field(24; "X-Axis Show Title"; Boolean)
        {
            Caption = 'X-Axis Show Title';
            InitValue = true;
        }
        field(30; "Y-Axis Fields"; Integer)
        {
            CalcFormula = count("Generic Chart Y-Axis" where(ID = field(ID)));
            Caption = 'Y-Axis Fields';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Y-Axis Title"; Text[250])
        {
            Caption = 'Y-Axis Title';
        }
        field(32; "Y-Axis Show Title"; Boolean)
        {
            Caption = 'Y-Axis Show Title';
            InitValue = true;
        }
        field(34; "Z-Axis Field ID"; Integer)
        {
            Caption = 'Z-Axis Field ID';
        }
        field(35; "Z-Axis Field Name"; Text[80])
        {
            Caption = 'Z-Axis Field Name';
        }
        field(36; "Z-Axis Field Caption"; Text[250])
        {
            Caption = 'Z-Axis Field Caption';
        }
        field(38; "Z-Axis Title"; Text[250])
        {
            Caption = 'Z-Axis Title';
        }
        field(39; "Z-Axis Show Title"; Boolean)
        {
            Caption = 'Z-Axis Show Title';
        }
        field(40; "Chart Exists"; Boolean)
        {
            CalcFormula = exist(Chart where(ID = field(ID)));
            Caption = 'Chart Exists';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

