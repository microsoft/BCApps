#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 135001 TableWithFieldCaption
#pragma warning restore AS0103, PTE0004
{
    DataClassification = SystemMetadata;
    ReplicateData = false;
    
    fields
    {
        field(1; "Entry No."; Integer)
        {

        }
        field(2; MyField; Integer)
        {
            Caption = 'MyCaption';
        }
        field(3; MyCaption; Integer)
        {
            Caption = 'MyField';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}