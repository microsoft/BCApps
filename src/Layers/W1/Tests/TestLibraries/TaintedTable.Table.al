table 130011 "Tainted Table"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Snapshot No."; Integer)
        {
            TableRelation = Snapshot."Snapshot No." where("Snapshot No." = field("Snapshot No."));
        }
        field(2; "Table No."; Integer)
        {
        }
        field(3; "Implicit Taint"; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; "Snapshot No.", "Table No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

