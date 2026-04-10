table 134093 "Table With Link To G/L Account"
{
    LookupPageID = "Table With Link To G/L Account";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Account No."; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
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

