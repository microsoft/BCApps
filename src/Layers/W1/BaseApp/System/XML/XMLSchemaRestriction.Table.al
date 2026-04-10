namespace System.Xml;

table 9611 "XML Schema Restriction"
{
    Caption = 'XML Schema Restriction';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "XML Schema Code"; Code[20])
        {
            Caption = 'XML Schema Code';
            TableRelation = "XML Schema Element"."XML Schema Code";
        }
        field(2; "Element ID"; Integer)
        {
            Caption = 'Element ID';
            TableRelation = "XML Schema Element".ID where("XML Schema Code" = field("XML Schema Code"));
        }
        field(3; ID; Integer)
        {
            Caption = 'ID';
        }
        field(4; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(25; "Simple Data Type"; Text[50])
        {
            Caption = 'Simple Data Type';
            Editable = false;
        }
        field(26; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Value,Base';
            OptionMembers = Value,Base;
        }
    }

    keys
    {
        key(Key1; "XML Schema Code", "Element ID", ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

