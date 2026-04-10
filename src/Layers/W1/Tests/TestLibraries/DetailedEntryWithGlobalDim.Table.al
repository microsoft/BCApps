table 134485 "Detailed Entry With Global Dim"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Parent Entry No."; Integer)
        {
            TableRelation = "Table With Dimension Set ID";
        }
        field(3; "Initial Entry Global Dim. 1"; Code[20])
        {
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(4; "Initial Entry Global Dim. 2"; Code[20])
        {
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

