#pragma warning disable AA0247
table 17321 "Tax Diff. Group"
{
    Caption = 'Deferral Group';
    LookupPageID = "Tax Diff. Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Tax Diff. Code"; Code[10])
        {
            Caption = 'Tax Diff. Code';
            TableRelation = "Tax Difference";
        }
        field(3; "Calculation Type"; Option)
        {
            Caption = 'Calculation Type';
            OptionCaption = 'Per Item,Total';
            OptionMembers = "Per Item",Total;
        }
        field(4; Description; Text[30])
        {
            Caption = 'Description';
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

