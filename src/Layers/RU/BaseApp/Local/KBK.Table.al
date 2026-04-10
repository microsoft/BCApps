#pragma warning disable AA0247
table 12426 KBK
{
    Caption = 'KBK';
    LookupPageID = "KBK Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(3; "Name 1"; Text[250])
        {
            Caption = 'Name 1';
        }
        field(4; "Name 2"; Text[250])
        {
            Caption = 'Name 2';
        }
        field(5; "Name 3"; Text[250])
        {
            Caption = 'Name 3';
        }
        field(6; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(7; Header; Boolean)
        {
            Caption = 'Header';
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
        fieldgroup(DropDown; "Code", "Name 1")
        {
        }
    }
}

