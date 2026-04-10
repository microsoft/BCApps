#pragma warning disable AA0247
table 17219 "Tax Register Dim. Corr. Filter"
{
    Caption = 'Tax Register Dim. Corr. Filter';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "G/L Corr. Entry No."; Integer)
        {
            Caption = 'G/L Corr. Entry No.';
        }
        field(2; "Connection Entry No."; Integer)
        {
            Caption = 'Connection Entry No.';
        }
        field(3; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
        }
        field(4; "Connection Type"; Option)
        {
            Caption = 'Connection Type';
            OptionCaption = 'Filters,Combinations';
            OptionMembers = Filters,Combinations;
        }
    }

    keys
    {
        key(Key1; "Section Code", "G/L Corr. Entry No.", "Connection Type", "Connection Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

