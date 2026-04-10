#pragma warning disable AA0247
table 14920 "Assessed Tax Allowance"
{
    Caption = 'Assessed Tax Allowance';
    LookupPageID = "Assessed Tax Allowances";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[7])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Article Number"; Code[4])
        {
            Caption = 'Article Number';
        }
        field(4; "Clause Number"; Code[4])
        {
            Caption = 'Clause Number';
        }
        field(5; "Subclause Number"; Code[4])
        {
            Caption = 'Subclause Number';
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

