namespace System.Xml;

table 9612 "Referenced XML Schema"
{
    Caption = 'Referenced XML Schema';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; "Referenced Schema Code"; Code[20])
        {
            Caption = 'Referenced Schema Code';
        }
        field(3; "Referenced Schema Namespace"; Text[250])
        {
            Caption = 'Referenced Schema Namespace';
        }
    }

    keys
    {
        key(Key1; "Code", "Referenced Schema Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

