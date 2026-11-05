#pragma warning disable AA0247
#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 19299 "India Migration Company"
#pragma warning restore AS0103, PTE0004
{
    DataPerCompany = false;
    DataClassification = CustomerContent;
    fields
    {
        field(1; Name; Text[30])
        {
            DataClassification = CustomerContent;
        }
        field(2; Status; Enum "Migration Status")
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }
}
