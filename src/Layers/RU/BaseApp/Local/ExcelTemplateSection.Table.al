#pragma warning disable AA0247
table 14931 "Excel Template Section"
{
    Caption = 'Excel Template Section';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Template Code"; Code[10])
        {
            Caption = 'Template Code';
            TableRelation = "Excel Template";
        }
        field(2; "Sheet Name"; Text[31])
        {
            Caption = 'Sheet Name';
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
        }
        field(4; Height; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Height';
        }
    }

    keys
    {
        key(Key1; "Template Code", "Sheet Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

