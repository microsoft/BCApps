table 130061 "Reference data"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Ref. file name"; Text[30])
        {
        }
        field(2; "Row no."; Integer)
        {
        }
        field(3; "Key"; RecordID)
        {
            Enabled = false;
        }
        field(4; "Field ID"; Integer)
        {
        }
        field(5; "Expected value"; Text[30])
        {
        }
    }

    keys
    {
        key(Key1; "Ref. file name", "Row no.", "Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

