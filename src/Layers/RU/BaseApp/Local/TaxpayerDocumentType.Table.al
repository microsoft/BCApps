#pragma warning disable AA0247
table 12429 "Taxpayer Document Type"
{
    Caption = 'Taxpayer Document Type';
    LookupPageID = "Taxpayer Document Types";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[2])
        {
            Caption = 'Code';
        }
        field(2; "Document Name"; Text[100])
        {
            Caption = 'Document Name';
        }
        field(3; Note; Text[250])
        {
            Caption = 'Note';
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
        fieldgroup(DropDown; "Code", "Document Name")
        {
        }
    }
}

