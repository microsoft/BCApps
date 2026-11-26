#pragma warning disable AA0247
#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 139758 "MDM Test Table B"
#pragma warning restore AS0103, PTE0004
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
        }
        field(3; "TableA Reference"; Code[20])
        {
            Caption = 'TableA Reference';
            TableRelation = "MDM Test Table A"."Primary Key";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
