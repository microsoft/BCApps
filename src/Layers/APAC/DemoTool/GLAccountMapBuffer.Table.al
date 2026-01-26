table 101903 "G/L Account Map Buffer"
{
    Caption = 'G/L Account Map Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Code[20])
        {
            Caption = 'Key';
            DataClassification = SystemMetadata;
        }
        field(2; Value; Code[20])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Key")
        {
        }
    }

    fieldgroups
    {
    }
}

