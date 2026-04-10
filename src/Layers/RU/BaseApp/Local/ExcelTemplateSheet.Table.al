#pragma warning disable AA0247
table 14930 "Excel Template Sheet"
{
    Caption = 'Excel Template Sheet';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Template Code"; Code[10])
        {
            Caption = 'Template Code';
            TableRelation = "Excel Template";
        }
        field(2; Name; Text[31])
        {
            Caption = 'Name';
        }
        field(3; "Paper Height"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Paper Height';
        }
    }

    keys
    {
        key(Key1; "Template Code", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

