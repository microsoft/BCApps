#pragma warning disable AA0247
table 12475 "Precious Metal"
{
    Caption = 'Precious Metal';
    DrillDownPageID = "Precious Metal";
    LookupPageID = "Precious Metal";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
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
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }
}

