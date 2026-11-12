#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 130061 "Reference data"
#pragma warning restore AS0103, PTE0004
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

