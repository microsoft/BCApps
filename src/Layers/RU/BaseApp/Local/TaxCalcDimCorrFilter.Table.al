#pragma warning disable AA0247
table 17320 "Tax Calc. Dim. Corr. Filter"
{
    Caption = 'Tax Calc. Dim. Corr. Filter';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Corresp. Entry No."; Integer)
        {
            Caption = 'Corresp. Entry No.';
        }
        field(2; "Connection Entry No."; Integer)
        {
            Caption = 'Connection Entry No.';
        }
        field(3; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
        }
    }

    keys
    {
        key(Key1; "Section Code", "Corresp. Entry No.", "Connection Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

