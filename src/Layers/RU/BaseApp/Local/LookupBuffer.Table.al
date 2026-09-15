#pragma warning disable AA0247
table 17223 "Lookup Buffer"
{
    Caption = 'Lookup Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(2; "Integer"; Integer)
        {
            Caption = 'Integer';
            DataClassification = SystemMetadata;
        }
        field(3; Text; Text[250])
        {
            Caption = 'Text';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Code", "Integer")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

