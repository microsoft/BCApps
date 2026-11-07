namespace Microsoft.HumanResources.Test;

#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 131322 "Watch Employee"
#pragma warning restore AS0103, PTE0004
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Employee No."; Code[20])
        {
        }
        field(3; "Original LE Count"; Integer)
        {
        }
        field(4; "Original Dtld. LE Count"; Integer)
        {
        }
        field(5; "Watch LE"; Boolean)
        {
        }
        field(6; "Watch Dtld. LE"; Boolean)
        {
        }
        field(7; "LE Comparison Method"; Option)
        {
            OptionMembers = Equal,"Greater Than","Less Than";
        }
        field(8; "Dtld. LE Comparison Method"; Option)
        {
            OptionMembers = Equal,"Greater Than","Less Than";
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

